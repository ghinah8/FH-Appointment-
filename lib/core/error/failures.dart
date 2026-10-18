import 'package:equatable/equatable.dart';

enum AuthFailureCode {
  invalidCredentials,
  emailNotConfirmed,
  userExists,
  weakPassword,
  unknown,
}

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code = AuthFailureCode.unknown});
  final AuthFailureCode code;

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ غير متوقع، حاول مرة أخرى']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تحقق من اتصالك بالإنترنت']);
}

/// أخطاء منطق الحجز القادمة من دوال قاعدة البيانات (RAISE EXCEPTION '<code>')
class BookingFailure extends Failure {
  const BookingFailure(super.message, this.code);
  final String code;

  @override
  List<Object?> get props => [message, code];

  static const _messages = {
    'slot_unavailable': 'هذا الموعد لم يعد متاحاً، اختر موعداً آخر',
    'email_not_verified': 'يجب التحقق من بريدك الإلكتروني قبل الحجز',
    'change_window_closed':
        'يمكن طلب الإلغاء أو التعديل حتى اليوم السابق للموعد فقط',
    'invalid_state': 'لا يمكن تنفيذ هذا الإجراء على الموعد في حالته الحالية',
    'forbidden': 'ليس لديك صلاحية لتنفيذ هذا الإجراء',
    'not_found': 'العنصر المطلوب غير موجود',
    'not_authenticated': 'يرجى تسجيل الدخول أولاً',
  };

  factory BookingFailure.fromCode(String code) =>
      BookingFailure(_messages[code] ?? 'تعذّر تنفيذ العملية', code);
}
