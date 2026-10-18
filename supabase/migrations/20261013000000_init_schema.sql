-- =====================================================================
-- الآنسة فاطمة — موقع حجز الدروس
-- Migration 001: الأنواع والجداول والفهارس
-- المرجع: وثيقة المتطلبات v1.3
-- =====================================================================

create extension if not exists btree_gist;

-- ---------- Enums ----------
create type public.user_role as enum ('student', 'admin');

create type public.appointment_status as enum (
  'pending',                 -- طلب حجز بانتظار القرار
  'confirmed',               -- مؤكد
  'rejected',                -- مرفوض
  'cancellation_requested',  -- الطالب طلب الإلغاء (الموعد ما زال قائماً)
  'reschedule_requested',    -- الطالب طلب التعديل (الموعد ما زال قائماً)
  'cancelled',               -- ملغى
  'completed',               -- مكتمل
  'no_show',                 -- لم يحضر
  'expired'                  -- انتهت صلاحية الطلب
);

create type public.request_type   as enum ('cancellation', 'reschedule');
create type public.request_status as enum ('pending', 'approved', 'rejected', 'closed');
create type public.exception_type as enum ('closure', 'extra_hours');
create type public.notification_status as enum ('sent', 'failed', 'skipped');

-- ---------- إعدادات التطبيق (صف واحد) ----------
create table public.app_settings (
  id                   smallint primary key default 1 check (id = 1),
  timezone             text     not null default 'Asia/Damascus',
  location_address     text     not null default 'فرقان، دوار الصخرة',
  location_maps_url    text,
  booking_horizon_days smallint not null default 7  check (booking_horizon_days between 1 and 60),
  pending_hold_hours   smallint not null default 24 check (pending_hold_hours between 1 and 168),
  lesson_duration_label text    not null default 'من 30 إلى 45 دقيقة',
  updated_at           timestamptz not null default now()
);
insert into public.app_settings (id) values (1);

-- ---------- الجامعات ----------
create table public.universities (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  is_active   boolean not null default true,
  sort_order  smallint not null default 0
);

-- ---------- الملفات الشخصية ----------
create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  full_name      text not null,
  phone          text,                                   -- مع رمز الدولة
  university_id  uuid references public.universities (id),
  study_year     text check (study_year in ('fourth', 'fifth')),
  is_graduating  boolean not null default false,         -- سنة تخرج (للسنة الخامسة فقط)
  avatar_url     text,
  role           public.user_role not null default 'student',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  check (not is_graduating or study_year = 'fifth')
);

-- ---------- الدوام الأسبوعي ----------
-- weekday: 0 = الأحد ... 6 = السبت  (يطابق extract(dow))
-- تبدأ المواعيد على رأس كل ساعة؛ آخر موعد يبدأ قبل end_time بمقدار slot_minutes
create table public.availability_rules (
  id            uuid primary key default gen_random_uuid(),
  weekday       smallint not null check (weekday between 0 and 6),
  start_time    time not null,
  end_time      time not null,
  slot_minutes  smallint not null default 60 check (slot_minutes between 15 and 240),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  check (end_time > start_time)
);
create index availability_rules_weekday_idx on public.availability_rules (weekday) where is_active;

-- ---------- العطل والاستثناءات ----------
-- closure     : إغلاق (يوم كامل إذا الوقت null، أو فترة محددة)
-- extra_hours : ساعات إضافية متاحة للحجز خارج الدوام
create table public.availability_exceptions (
  id          uuid primary key default gen_random_uuid(),
  date        date not null,
  type        public.exception_type not null default 'closure',
  start_time  time,
  end_time    time,
  reason      text,
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  check ((start_time is null) = (end_time is null)),
  check (end_time is null or end_time > start_time),
  check (type = 'closure' or start_time is not null)
);
create index availability_exceptions_date_idx on public.availability_exceptions (date);

-- ---------- المواعيد (الحجوزات) ----------
create table public.appointments (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.profiles (id) on delete cascade,
  starts_at     timestamptz not null,
  ends_at       timestamptz not null,
  status        public.appointment_status not null default 'pending',
  is_exceptional boolean not null default false,        -- موعد أنشأته المدرّسة خارج الدوام
  expires_at    timestamptz,                            -- صلاحية الطلب المعلّق: الأقرب من 24 ساعة أو بدء الدرس
  student_note  text,
  admin_note    text,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (ends_at > starts_at),
  check (status <> 'pending' or expires_at is not null),

  -- يمنع تداخل موعدين يحجزان الوقت (حتى مع الطلبات المتزامنة)
  constraint appointments_no_overlap exclude using gist (
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status in ('pending', 'confirmed', 'cancellation_requested', 'reschedule_requested'))
);
create index appointments_student_idx on public.appointments (student_id, starts_at desc);
create index appointments_status_idx  on public.appointments (status, starts_at);
create index appointments_pending_expiry_idx on public.appointments (expires_at) where status = 'pending';

-- ---------- طلبات الإلغاء والتعديل من الطالب ----------
create table public.appointment_requests (
  id                  uuid primary key default gen_random_uuid(),
  appointment_id      uuid not null references public.appointments (id) on delete cascade,
  student_id          uuid not null references public.profiles (id) on delete cascade,
  type                public.request_type not null,
  requested_starts_at timestamptz,                      -- الموعد الجديد المطلوب (للتعديل فقط)
  reason              text,
  status              public.request_status not null default 'pending',
  closed_reason       text,                             -- مثل: superseded_by_admin_edit
  admin_note          text,
  decided_by          uuid references public.profiles (id) on delete set null,
  decided_at          timestamptz,
  created_at          timestamptz not null default now(),
  check (type = 'reschedule' or requested_starts_at is null),
  check (type <> 'reschedule' or requested_starts_at is not null)
);
-- طلب واحد معلّق فقط لكل موعد
create unique index appointment_requests_one_pending
  on public.appointment_requests (appointment_id) where status = 'pending';
create index appointment_requests_status_idx on public.appointment_requests (status, created_at);

-- ---------- سجل الإجراءات (لا يُحذف) ----------
create table public.appointment_history (
  id              bigint generated always as identity primary key,
  appointment_id  uuid not null references public.appointments (id) on delete cascade,
  actor_id        uuid references public.profiles (id) on delete set null,
  action          text not null,
  from_status     public.appointment_status,
  to_status       public.appointment_status,
  old_starts_at   timestamptz,
  new_starts_at   timestamptz,
  reason          text,
  metadata        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now()
);
create index appointment_history_appt_idx on public.appointment_history (appointment_id, created_at);

-- ---------- إعدادات الإشعارات ----------
create table public.notification_settings (
  user_id               uuid primary key references public.profiles (id) on delete cascade,
  notifications_enabled boolean not null default true,
  reminder_24h          boolean not null default true,
  web_push_enabled      boolean not null default false,
  updated_at            timestamptz not null default now()
);

create table public.push_subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  token       text not null,
  platform    text not null default 'web',
  created_at  timestamptz not null default now(),
  unique (user_id, token)
);

-- ---------- سجل الإشعارات (لمنع التكرار) ----------
create table public.notification_log (
  id                    bigint generated always as identity primary key,
  appointment_id        uuid not null references public.appointments (id) on delete cascade,
  user_id               uuid not null references public.profiles (id) on delete cascade,
  kind                  text not null default 'reminder_24h',
  appointment_starts_at timestamptz not null,           -- لقطة من وقت الموعد وقت الإرسال
  status                public.notification_status not null,
  error                 text,
  created_at            timestamptz not null default now()
);
-- لا يُرسل التذكير الناجح نفسه مرتين لنفس وقت الموعد؛ تغيّر الوقت يسمح بتذكير جديد
create unique index notification_log_sent_once
  on public.notification_log (appointment_id, kind, appointment_starts_at) where status = 'sent';
