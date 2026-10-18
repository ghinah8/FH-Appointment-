/// مدقّقات نماذج الإدخال (رسائل عربية)
class Validators {
  const Validators._();

  static String? required(String? v, [String field = 'هذا الحقل']) =>
      (v == null || v.trim().isEmpty) ? '$field مطلوب' : null;

  static String? email(String? v) {
    final r = required(v, 'البريد الإلكتروني');
    if (r != null) return r;
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim());
    return ok ? null : 'صيغة البريد الإلكتروني غير صحيحة';
  }

  /// رقم دولي مع رمز الدولة مثل: +963 912 345 678
  static String? phoneWithCountryCode(String? v) {
    final r = required(v, 'رقم الهاتف');
    if (r != null) return r;
    final cleaned = normalizePhone(v!);
    return RegExp(r'^\+\d{8,15}$').hasMatch(cleaned)
        ? null
        : 'أدخل الرقم مع رمز الدولة، مثال: +963912345678';
  }

  static String normalizePhone(String v) =>
      v.replaceAll(RegExp(r'[\s\-()]'), '');

  static String? password(String? v) {
    final r = required(v, 'كلمة المرور');
    if (r != null) return r;
    return v!.length >= 8 ? null : 'كلمة المرور 8 أحرف على الأقل';
  }

  static String? Function(String?) matches(String Function() other) =>
      (v) => v == other() ? null : 'كلمتا المرور غير متطابقتين';
}
