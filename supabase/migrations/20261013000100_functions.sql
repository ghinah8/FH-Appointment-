-- =====================================================================
-- Migration 002: الدوال والـ Triggers (منطق الحجز على الخادم)
-- كل تغيير في حالة الموعد يمر عبر هذه الدوال فقط (SECURITY DEFINER)
-- رسائل الأخطاء رموز ثابتة تقرأها الواجهة: slot_unavailable, email_not_verified, ...
-- =====================================================================

-- ---------- مساعدات ----------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch      before update on public.profiles      for each row execute function public.touch_updated_at();
create trigger appointments_touch  before update on public.appointments  for each row execute function public.touch_updated_at();
create trigger notif_settings_touch before update on public.notification_settings for each row execute function public.touch_updated_at();
create trigger app_settings_touch  before update on public.app_settings  for each row execute function public.touch_updated_at();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.require_admin()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
end $$;

create or replace function public.log_history(
  p_appointment uuid, p_action text,
  p_from public.appointment_status, p_to public.appointment_status,
  p_old_start timestamptz default null, p_new_start timestamptz default null,
  p_reason text default null, p_meta jsonb default '{}'::jsonb)
returns void language sql security definer set search_path = public as $$
  insert into public.appointment_history
    (appointment_id, actor_id, action, from_status, to_status, old_starts_at, new_starts_at, reason, metadata)
  values (p_appointment, auth.uid(), p_action, p_from, p_to, p_old_start, p_new_start, p_reason, p_meta);
$$;

-- ---------- إنشاء الملف الشخصي عند التسجيل ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_uni  uuid;
  v_year text;
  v_grad boolean := false;
begin
  begin v_uni := nullif(new.raw_user_meta_data ->> 'university_id', '')::uuid;
  exception when others then v_uni := null; end;

  v_year := new.raw_user_meta_data ->> 'study_year';
  if v_year not in ('fourth', 'fifth') then v_year := null; end if;

  begin v_grad := coalesce((new.raw_user_meta_data ->> 'is_graduating')::boolean, false);
  exception when others then v_grad := false; end;
  if v_year is distinct from 'fifth' then v_grad := false; end if;

  insert into public.profiles (id, full_name, phone, university_id, study_year, is_graduating)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(new.email, '@', 1)),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    v_uni, v_year, v_grad
  );

  insert into public.notification_settings (user_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- المواعيد المتاحة (7 أيام من اليوم، بتوقيت سوريا) ----------
create or replace function public.get_available_slots()
returns table (slot_start timestamptz, slot_end timestamptz)
language sql stable security definer set search_path = public as $$
  with s as (
    select timezone as tz, booking_horizon_days as horizon from public.app_settings where id = 1
  ),
  days as (
    select g::date as d
    from s,
         generate_series((now() at time zone s.tz)::date,
                         (now() at time zone s.tz)::date + (s.horizon - 1),
                         interval '1 day') g
  ),
  windows as (
    select days.d, r.start_time, r.end_time, r.slot_minutes
    from days
    join public.availability_rules r
      on r.is_active and r.weekday = extract(dow from days.d)::int
    union all
    select e.date, e.start_time, e.end_time, 60::smallint
    from public.availability_exceptions e
    where e.type = 'extra_hours' and e.date in (select d from days)
  ),
  cand as (
    select (gs at time zone s.tz) as st,
           (gs at time zone s.tz) + make_interval(mins => w.slot_minutes) as en,
           s.tz
    from windows w
    cross join s
    cross join lateral generate_series(
      w.d + w.start_time,
      w.d + w.end_time - make_interval(mins => w.slot_minutes),
      make_interval(mins => w.slot_minutes)
    ) gs
  )
  select distinct c.st, c.en
  from cand c
  where c.st > now()
    -- ليس ضمن إغلاق أو عطلة
    and not exists (
      select 1 from public.availability_exceptions e
      where e.type = 'closure'
        and e.date = (c.st at time zone c.tz)::date
        and (e.start_time is null
             or ((c.st at time zone c.tz)::time < e.end_time
                 and (c.en at time zone c.tz)::time > e.start_time))
    )
    -- ليس محجوزاً (الطلب المعلّق ينتهي حجزه بانتهاء expires_at)
    and not exists (
      select 1 from public.appointments a
      where a.starts_at < c.en and a.ends_at > c.st
        and (a.status in ('confirmed', 'cancellation_requested', 'reschedule_requested')
             or (a.status = 'pending' and a.expires_at > now()))
    )
  order by 1;
$$;

-- ---------- انتهاء صلاحية الطلبات المعلّقة (يُستدعى من الـ Cron وقبل كل حجز) ----------
create or replace function public.expire_stale_pending()
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  with e as (
    update public.appointments
       set status = 'expired'
     where status = 'pending' and expires_at <= now()
    returning id
  )
  insert into public.appointment_history (appointment_id, action, from_status, to_status, reason)
  select id, 'expired', 'pending', 'expired', 'hold_elapsed' from e;

  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- ---------- الطالب: طلب حجز ----------
create or replace function public.create_appointment(p_starts_at timestamptz, p_note text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_end  timestamptz;
  v_hold smallint;
  v_row  public.appointments;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;

  if not exists (select 1 from auth.users where id = v_uid and email_confirmed_at is not null) then
    raise exception 'email_not_verified';
  end if;

  perform public.expire_stale_pending();

  select slot_end into v_end from public.get_available_slots() where slot_start = p_starts_at;
  if v_end is null then raise exception 'slot_unavailable'; end if;

  select pending_hold_hours into v_hold from public.app_settings where id = 1;

  begin
    insert into public.appointments (student_id, starts_at, ends_at, status, student_note, expires_at, created_by)
    values (v_uid, p_starts_at, v_end, 'pending', p_note,
            least(now() + make_interval(hours => v_hold), p_starts_at), v_uid)
    returning * into v_row;
  exception when exclusion_violation then
    raise exception 'slot_unavailable';
  end;

  perform public.log_history(v_row.id, 'created', null, 'pending', null, v_row.starts_at);
  return v_row;
end $$;

-- ---------- الطالب: طلب إلغاء/تعديل (اليوم التقويمي السابق للموعد فقط) ----------
create or replace function public.request_appointment_change(
  p_appointment_id uuid,
  p_type public.request_type,
  p_new_starts_at timestamptz default null,
  p_reason text default null)
returns public.appointment_requests
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_tz  text;
  v_a   public.appointments;
  v_req public.appointment_requests;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;

  select timezone into v_tz from public.app_settings where id = 1;

  select * into v_a from public.appointments
   where id = p_appointment_id and student_id = v_uid for update;
  if not found then raise exception 'not_found'; end if;
  if v_a.status <> 'confirmed' then raise exception 'invalid_state'; end if;

  -- لا طلبات في يوم الموعد نفسه أو بعده
  if (now() at time zone v_tz)::date >= (v_a.starts_at at time zone v_tz)::date then
    raise exception 'change_window_closed';
  end if;

  if p_type = 'reschedule' then
    if p_new_starts_at is null then raise exception 'new_time_required'; end if;
    if not exists (select 1 from public.get_available_slots() where slot_start = p_new_starts_at) then
      raise exception 'slot_unavailable';
    end if;
  end if;

  insert into public.appointment_requests (appointment_id, student_id, type, requested_starts_at, reason)
  values (v_a.id, v_uid, p_type,
          case when p_type = 'reschedule' then p_new_starts_at end, p_reason)
  returning * into v_req;

  update public.appointments
     set status = case p_type when 'cancellation' then 'cancellation_requested'::public.appointment_status
                              else 'reschedule_requested'::public.appointment_status end
   where id = v_a.id;

  perform public.log_history(v_a.id, 'change_requested', v_a.status,
    case p_type when 'cancellation' then 'cancellation_requested'::public.appointment_status
                else 'reschedule_requested'::public.appointment_status end,
    v_a.starts_at, p_new_starts_at, p_reason, jsonb_build_object('type', p_type));

  return v_req;
end $$;

-- ---------- الإدارة: قبول/رفض طلب الحجز ----------
create or replace function public.admin_decide_appointment(
  p_id uuid, p_confirm boolean, p_note text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare v_a public.appointments; v_to public.appointment_status;
begin
  perform public.require_admin();
  perform public.expire_stale_pending();

  select * into v_a from public.appointments where id = p_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_a.status <> 'pending' then raise exception 'invalid_state'; end if;

  v_to := case when p_confirm then 'confirmed' else 'rejected' end;

  update public.appointments
     set status = v_to, admin_note = coalesce(p_note, admin_note), expires_at = null
   where id = p_id returning * into v_a;

  perform public.log_history(p_id, case when p_confirm then 'confirmed' else 'rejected' end,
                             'pending', v_to, v_a.starts_at, v_a.starts_at, p_note);
  return v_a;
end $$;

-- ---------- الإدارة: قبول/رفض طلب إلغاء أو تعديل من الطالب ----------
create or replace function public.admin_decide_request(
  p_request_id uuid, p_approve boolean,
  p_new_starts_at timestamptz default null, p_note text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare
  v_req public.appointment_requests;
  v_a   public.appointments;
  v_new timestamptz;
  v_dur interval;
begin
  perform public.require_admin();

  select * into v_req from public.appointment_requests
   where id = p_request_id and status = 'pending' for update;
  if not found then raise exception 'not_found'; end if;

  select * into v_a from public.appointments where id = v_req.appointment_id for update;

  if not p_approve then
    -- الرفض: يبقى الموعد الأصلي كما هو
    update public.appointment_requests
       set status = 'rejected', admin_note = p_note, decided_by = auth.uid(), decided_at = now()
     where id = v_req.id;
    update public.appointments set status = 'confirmed' where id = v_a.id returning * into v_a;
    perform public.log_history(v_a.id, 'request_rejected', null, 'confirmed',
                               v_a.starts_at, v_a.starts_at, p_note, jsonb_build_object('type', v_req.type));
    return v_a;
  end if;

  if v_req.type = 'cancellation' then
    update public.appointments set status = 'cancelled' where id = v_a.id returning * into v_a;
    perform public.log_history(v_a.id, 'request_approved', null, 'cancelled',
                               v_a.starts_at, null, p_note, jsonb_build_object('type', 'cancellation'));
  else
    v_new := coalesce(p_new_starts_at, v_req.requested_starts_at);
    v_dur := v_a.ends_at - v_a.starts_at;
    begin
      update public.appointments
         set starts_at = v_new, ends_at = v_new + v_dur, status = 'confirmed'
       where id = v_a.id returning * into v_a;
    exception when exclusion_violation then
      raise exception 'slot_unavailable';
    end;
    perform public.log_history(v_a.id, 'request_approved', null, 'confirmed',
                               v_req.requested_starts_at, v_a.starts_at, p_note,
                               jsonb_build_object('type', 'reschedule'));
  end if;

  update public.appointment_requests
     set status = 'approved', admin_note = p_note, decided_by = auth.uid(), decided_at = now()
   where id = v_req.id;

  return v_a;
end $$;

-- ---------- الإدارة: تعديل موعد في أي وقت ----------
-- يُغلق أي طلب تعديل/إلغاء معلّق تلقائياً بسبب superseded_by_admin_edit (دون حذفه)
create or replace function public.admin_update_appointment(
  p_id uuid, p_new_starts_at timestamptz, p_reason text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare v_a public.appointments; v_old timestamptz; v_from public.appointment_status; v_dur interval;
begin
  perform public.require_admin();

  select * into v_a from public.appointments where id = p_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_a.status not in ('pending', 'confirmed', 'cancellation_requested', 'reschedule_requested') then
    raise exception 'invalid_state';
  end if;

  v_old := v_a.starts_at; v_from := v_a.status; v_dur := v_a.ends_at - v_a.starts_at;

  begin
    update public.appointments
       set starts_at = p_new_starts_at,
           ends_at   = p_new_starts_at + v_dur,
           status    = case when status in ('cancellation_requested', 'reschedule_requested')
                            then 'confirmed'::public.appointment_status else status end,
           expires_at = case when status = 'pending' then least(expires_at, p_new_starts_at) else expires_at end
     where id = p_id returning * into v_a;
  exception when exclusion_violation then
    raise exception 'slot_unavailable';
  end;

  update public.appointment_requests
     set status = 'closed', closed_reason = 'superseded_by_admin_edit',
         decided_by = auth.uid(), decided_at = now()
   where appointment_id = p_id and status = 'pending';

  perform public.log_history(p_id, 'admin_rescheduled', v_from, v_a.status, v_old, v_a.starts_at, p_reason);
  return v_a;
end $$;

-- ---------- الإدارة: إلغاء موعد ----------
create or replace function public.admin_cancel_appointment(p_id uuid, p_reason text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare v_a public.appointments; v_from public.appointment_status;
begin
  perform public.require_admin();

  select * into v_a from public.appointments where id = p_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_a.status not in ('pending', 'confirmed', 'cancellation_requested', 'reschedule_requested') then
    raise exception 'invalid_state';
  end if;
  v_from := v_a.status;

  update public.appointments set status = 'cancelled', admin_note = coalesce(p_reason, admin_note)
   where id = p_id returning * into v_a;

  update public.appointment_requests
     set status = 'closed', closed_reason = 'closed_by_admin_cancellation',
         decided_by = auth.uid(), decided_at = now()
   where appointment_id = p_id and status = 'pending';

  perform public.log_history(p_id, 'admin_cancelled', v_from, 'cancelled', v_a.starts_at, null, p_reason);
  return v_a;
end $$;

-- ---------- الإدارة: موعد استثنائي (مؤكد مباشرة، خارج الدوام) ----------
create or replace function public.admin_create_appointment(
  p_student_id uuid, p_starts_at timestamptz, p_minutes integer default 60, p_note text default null)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare v_a public.appointments;
begin
  perform public.require_admin();
  perform public.expire_stale_pending();

  begin
    insert into public.appointments
      (student_id, starts_at, ends_at, status, is_exceptional, admin_note, created_by)
    values (p_student_id, p_starts_at, p_starts_at + make_interval(mins => p_minutes),
            'confirmed', true, p_note, auth.uid())
    returning * into v_a;
  exception when exclusion_violation then
    raise exception 'slot_unavailable';
  end;

  perform public.log_history(v_a.id, 'admin_created', null, 'confirmed', null, v_a.starts_at, p_note);
  return v_a;
end $$;

-- ---------- الإدارة: تسجيل الحضور أو الغياب ----------
create or replace function public.admin_set_attendance(p_id uuid, p_outcome text)
returns public.appointments
language plpgsql security definer set search_path = public as $$
declare v_a public.appointments; v_to public.appointment_status;
begin
  perform public.require_admin();
  if p_outcome not in ('completed', 'no_show') then raise exception 'invalid_outcome'; end if;

  select * into v_a from public.appointments where id = p_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_a.status <> 'confirmed' then raise exception 'invalid_state'; end if;
  if v_a.starts_at > now() then raise exception 'too_early'; end if;

  v_to := p_outcome::public.appointment_status;
  update public.appointments set status = v_to where id = p_id returning * into v_a;
  perform public.log_history(p_id, 'attendance', 'confirmed', v_to, v_a.starts_at, v_a.starts_at);
  return v_a;
end $$;

-- ---------- الإدارة: تعارضات الدوام مع حجوزات قائمة ----------
-- تُعرض لتُعالج صراحةً، ولا تُحذف الحجوزات تلقائياً
create or replace function public.get_schedule_conflicts()
returns setof public.appointments
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.require_admin();
  return query
  select a.* from public.appointments a, public.app_settings s
   where s.id = 1
     and a.starts_at > now()
     and a.status in ('confirmed', 'cancellation_requested', 'reschedule_requested')
     and not a.is_exceptional
     and (
       -- لا يوجد دوام يغطي الموعد
       not exists (
         select 1 from public.availability_rules r
          where r.is_active
            and r.weekday = extract(dow from (a.starts_at at time zone s.timezone))::int
            and (a.starts_at at time zone s.timezone)::time >= r.start_time
            and (a.ends_at   at time zone s.timezone)::time <= r.end_time
       )
       or
       -- أو يقع ضمن إغلاق
       exists (
         select 1 from public.availability_exceptions e
          where e.type = 'closure'
            and e.date = (a.starts_at at time zone s.timezone)::date
            and (e.start_time is null
                 or ((a.starts_at at time zone s.timezone)::time < e.end_time
                     and (a.ends_at at time zone s.timezone)::time > e.start_time))
       )
     )
     and not exists (
       -- ويغطيه ساعات إضافية
       select 1 from public.availability_exceptions x
        where x.type = 'extra_hours'
          and x.date = (a.starts_at at time zone s.timezone)::date
          and (a.starts_at at time zone s.timezone)::time >= x.start_time
          and (a.ends_at   at time zone s.timezone)::time <= x.end_time
     )
   order by a.starts_at;
end $$;

-- ---------- التذكيرات المستحقة (تستدعيها Edge Function بصلاحية service_role) ----------
create or replace function public.get_due_reminders()
returns table (
  appointment_id uuid, student_id uuid, starts_at timestamptz,
  full_name text, tokens text[])
language sql stable security definer set search_path = public as $$
  select a.id, a.student_id, a.starts_at, p.full_name,
         coalesce(array_agg(ps.token) filter (where ps.token is not null), '{}')
  from public.appointments a
  join public.profiles p on p.id = a.student_id
  join public.notification_settings ns
    on ns.user_id = a.student_id
   and ns.notifications_enabled and ns.reminder_24h and ns.web_push_enabled
  left join public.push_subscriptions ps on ps.user_id = a.student_id
  where a.status = 'confirmed'
    and a.starts_at > now()
    and a.starts_at - interval '24 hours' <= now()
    and not exists (
      select 1 from public.notification_log nl
       where nl.appointment_id = a.id and nl.kind = 'reminder_24h'
         and nl.appointment_starts_at = a.starts_at and nl.status = 'sent')
  group by a.id, a.student_id, a.starts_at, p.full_name;
$$;
