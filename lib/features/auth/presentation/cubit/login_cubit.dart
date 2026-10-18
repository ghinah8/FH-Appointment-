import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/auth_usecases.dart';

enum FormStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = FormStatus.initial,
    this.error,
    this.code,
    this.info,
  });

  final FormStatus status;
  final String? error;
  final AuthFailureCode? code;

  /// رسالة نجاح عابرة (مثل: أُرسل رابط التحقق)
  final String? info;

  bool get needsVerification => code == AuthFailureCode.emailNotConfirmed;

  @override
  List<Object?> get props => [status, error, code, info];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required SignIn signIn,
    required ResendVerification resendVerification,
    required SendPasswordReset sendPasswordReset,
  })  : _signIn = signIn,
        _resend = resendVerification,
        _reset = sendPasswordReset,
        super(const LoginState());

  final SignIn _signIn;
  final ResendVerification _resend;
  final SendPasswordReset _reset;

  Future<void> submit(String email, String password) async {
    emit(const LoginState(status: FormStatus.loading));
    final res = await _signIn(SignInParams(email: email, password: password));
    res.fold(
      (f) => emit(LoginState(
        status: FormStatus.failure,
        error: f.message,
        code: f is AuthFailure ? f.code : null,
      )),
      // عند النجاح يلتقط AuthCubit تغيّر الجلسة ويعيد الراوتر التوجيه
      (_) => emit(const LoginState(status: FormStatus.success)),
    );
  }

  Future<void> resendVerification(String email) async {
    final res = await _resend(email);
    res.fold(
      (f) => emit(LoginState(
          status: FormStatus.failure, error: f.message, code: state.code)),
      (_) => emit(const LoginState(
          status: FormStatus.initial,
          info: 'أرسلنا رسالة التحقق إلى بريدك الإلكتروني')),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    final res = await _reset(email);
    res.fold(
      (f) => emit(LoginState(status: FormStatus.failure, error: f.message)),
      (_) => emit(const LoginState(
          info: 'إذا كان البريد مسجّلاً سنرسل إليك رابط إعادة تعيين كلمة المرور')),
    );
  }
}
