-- =====================================================================
-- Migration 004: البيانات المرجعية + الجدولة
-- =====================================================================

-- الجامعات
insert into public.universities (name, sort_order) values
  ('جامعة الاتحاد', 1),
  ('جامعة قرطبة',   2),
  ('جامعة حلب',     3);

-- الدوام الأساسي: الأحد (0) والثلاثاء (2) والخميس (4) من 11:00 إلى 17:00
-- المواعيد تبدأ على رأس كل ساعة: 11 12 13 14 15 16  (الموعد الأخير 16:00-17:00)
insert into public.availability_rules (weekday, start_time, end_time, slot_minutes) values
  (0, '11:00', '17:00', 60),
  (2, '11:00', '17:00', 60),
  (4, '11:00', '17:00', 60);

-- عنوان المكان (رابط الخريطة تعدّله المدرّسة من لوحة التحكم)
update public.app_settings
   set location_address = 'فرقان، دوار الصخرة'
 where id = 1;

-- ---------- الجدولة: انتهاء الطلبات المعلّقة كل دقيقة ----------
-- pg_cron متاح على Supabase (Database → Extensions). إن لم يتوفر تُتخطى الخطوة دون فشل.
do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule(
    'expire-stale-pending',
    '* * * * *',
    $cron$ select public.expire_stale_pending(); $cron$
  );
exception when others then
  raise notice 'pg_cron غير متاح، فعّله من لوحة Supabase ثم أعد تشغيل هذه الخطوة: %', sqlerrm;
end $$;

-- التذكيرات: تُستدعى Edge Function باسم send-reminders كل 15 دقيقة (تُضبط من Supabase Dashboard → Cron
-- أو عبر pg_net) وهي تقرأ get_due_reminders() وتسجّل النتيجة في notification_log.
