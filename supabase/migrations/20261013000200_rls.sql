-- =====================================================================
-- Migration 003: RLS والصلاحيات
-- القاعدة: الطالب يقرأ بياناته فقط، وكل التعديلات على المواعيد عبر الدوال (RPC)
-- =====================================================================

alter table public.app_settings            enable row level security;
alter table public.universities            enable row level security;
alter table public.profiles                enable row level security;
alter table public.availability_rules      enable row level security;
alter table public.availability_exceptions enable row level security;
alter table public.appointments            enable row level security;
alter table public.appointment_requests    enable row level security;
alter table public.appointment_history     enable row level security;
alter table public.notification_settings   enable row level security;
alter table public.push_subscriptions      enable row level security;
alter table public.notification_log        enable row level security;

-- ---------- app_settings: القراءة للجميع (العنوان والخريطة)، التعديل للإدارة ----------
create policy app_settings_read   on public.app_settings for select to anon, authenticated using (true);
create policy app_settings_update on public.app_settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- universities: القراءة للجميع (صفحة التسجيل)، الإدارة للمدرّسة ----------
create policy universities_read  on public.universities for select to anon, authenticated
  using (is_active or public.is_admin());
create policy universities_admin on public.universities for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- profiles ----------
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- الطالب لا يغيّر role ولا غيره من الحقول الحساسة
revoke update on public.profiles from authenticated;
grant  update (full_name, phone, university_id, study_year, is_graduating, avatar_url)
  on public.profiles to authenticated;
revoke insert, delete on public.profiles from authenticated, anon;

-- ---------- الدوام والاستثناءات: الإدارة فقط (الطالب يرى النتيجة عبر get_available_slots) ----------
create policy availability_rules_admin on public.availability_rules for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy availability_exceptions_admin on public.availability_exceptions for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- appointments: قراءة فقط؛ لا كتابة مباشرة لأي أحد ----------
create policy appointments_select on public.appointments for select to authenticated
  using (student_id = auth.uid() or public.is_admin());
revoke insert, update, delete on public.appointments from authenticated, anon;

-- ---------- appointment_requests ----------
create policy appointment_requests_select on public.appointment_requests for select to authenticated
  using (student_id = auth.uid() or public.is_admin());
revoke insert, update, delete on public.appointment_requests from authenticated, anon;

-- ---------- appointment_history: للإدارة فقط ----------
create policy appointment_history_select on public.appointment_history for select to authenticated
  using (public.is_admin());
revoke insert, update, delete on public.appointment_history from authenticated, anon;

-- ---------- notification_settings / push_subscriptions: صاحبها فقط ----------
create policy notification_settings_own on public.notification_settings for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy push_subscriptions_own on public.push_subscriptions for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- notification_log: قراءة للإدارة، والكتابة من service_role فقط ----------
create policy notification_log_select on public.notification_log for select to authenticated
  using (public.is_admin());
revoke insert, update, delete on public.notification_log from authenticated, anon;

-- ---------- صلاحيات تنفيذ الدوال ----------
revoke execute on all functions in schema public from public, anon, authenticated;

-- is_admin تُستعمل داخل سياسات RLS التي تشمل anon (الجامعات والإعدادات)
grant execute on function public.is_admin()                                  to anon, authenticated;
grant execute on function public.get_available_slots()                       to authenticated;
grant execute on function public.create_appointment(timestamptz, text)       to authenticated;
grant execute on function public.request_appointment_change(uuid, public.request_type, timestamptz, text) to authenticated;

-- دوال الإدارة (تتحقق داخلياً من is_admin)
grant execute on function public.admin_decide_appointment(uuid, boolean, text)                 to authenticated;
grant execute on function public.admin_decide_request(uuid, boolean, timestamptz, text)        to authenticated;
grant execute on function public.admin_update_appointment(uuid, timestamptz, text)             to authenticated;
grant execute on function public.admin_cancel_appointment(uuid, text)                          to authenticated;
grant execute on function public.admin_create_appointment(uuid, timestamptz, integer, text)    to authenticated;
grant execute on function public.admin_set_attendance(uuid, text)                              to authenticated;
grant execute on function public.get_schedule_conflicts()                                      to authenticated;

-- للـ Cron والـ Edge Functions فقط
grant execute on function public.expire_stale_pending() to service_role;
grant execute on function public.get_due_reminders()    to service_role;
