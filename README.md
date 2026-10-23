# موقع حجز دروس الآنسة فاطمة

Flutter Web + Supabase (PostgreSQL + Auth + RLS) · BLoC/Cubit · Clean Architecture (feature-first)

## ما الموجود حالياً

| الجزء | الحالة |
|---|---|
| قاعدة البيانات (جداول، RLS، دوال الحجز، انتهاء الطلبات، التذكيرات) | جاهز ومُختبر على PostgreSQL 16 |
| هيكل Flutter (theme، router، DI، errors) | مكتوب، لم يُجمَّع بعد |
| ميزة `auth` (دخول، تسجيل، تحقق البريد) | مكتوبة، لم تُجمَّع بعد |
| الحجز، مواعيدي، لوحة الإدارة، الإشعارات | الخطوات التالية |

## 1) قاعدة البيانات

1. أنشئ مشروعاً في [Supabase](https://supabase.com).
2. نفّذ الملفات بالترتيب من `supabase/migrations/` في SQL Editor (أو `supabase db push`).
3. **Authentication → Providers → Email**: فعّل *Confirm email* (التحقق إلزامي).
4. **Authentication → URL Configuration**: ضع رابط الموقع في *Site URL*.
5. أنشئ حساب الآنسة فاطمة من صفحة التسجيل، ثم اجعله مديراً:

```sql
update public.profiles set role = 'admin' where id = (
  select id from auth.users where email = 'EMAIL_HERE'
);
```

6. عدّل رابط الخريطة:

```sql
update public.app_settings set location_maps_url = 'https://maps.app.goo.gl/...' where id = 1;
```

### قواعد مهمة في الداتا بيس
- الطالب لا يكتب في `appointments` مباشرة؛ كل شيء عبر دوال RPC:
  `create_appointment`، `request_appointment_change`، و`admin_*`.
- رموز الأخطاء (تقرأها الواجهة): `slot_unavailable`، `email_not_verified`،
  `change_window_closed`، `invalid_state`، `forbidden`، `not_found`.
- المواعيد المتاحة: `select * from get_available_slots()` (7 أيام بتوقيت سوريا).
- انتهاء الطلبات المعلّقة: `expire_stale_pending()` كل دقيقة عبر `pg_cron`
  (فعّل الإضافة من Database → Extensions، ثم أعد تشغيل آخر ملف migration).

## 2) تشغيل Flutter

لم يُنشأ مجلد `web/` ولا ملفات المنصات، ولّدها مرة واحدة:

```bash
flutter create . --platforms web --project-name fatima_habib
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SITE_URL=http://localhost:5000
```

> `flutter create .` لا يستبدل ملفات `lib/` الموجودة؛ إن أنشأ `test/widget_test.dart` قديماً احذفه.

## هيكل الكود

```
lib/
├── core/        config, di, error, router, theme, usecase, utils, widgets
├── features/
│   ├── auth/        data / domain / presentation
│   ├── booking/     (الصفحة الرئيسية مؤقتة حالياً)
│   ├── appointments/  (لاحقاً)
│   ├── profile/       (لاحقاً)
│   └── admin/         (لاحقاً)
└── main.dart
```
