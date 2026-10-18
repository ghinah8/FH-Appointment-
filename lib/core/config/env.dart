/// قيم الإعدادات تُمرَّر وقت التشغيل ولا تُكتب في الكود:
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=SITE_URL=http://localhost:5000
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// رابط الموقع الذي يعود إليه الطالب بعد الضغط على رابط التحقق من البريد.
  static const siteUrl = String.fromEnvironment('SITE_URL');

  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'مرّر SUPABASE_URL و SUPABASE_ANON_KEY عبر --dart-define',
    );
  }
}
