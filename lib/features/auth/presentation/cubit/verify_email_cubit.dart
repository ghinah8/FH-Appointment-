import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/auth_usecases.dart';
import 'login_cubit.dart' show FormStatus;

class VerifyEmailCubit extends Cubit<({FormStatus status, String? message})> {
  VerifyEmailCubit(this._resend)
      : super((status: FormStatus.initial, message: null));

  final ResendVerification _resend;

  Future<void> resend(String email) async {
    emit((status: FormStatus.loading, message: null));
    final res = await _resend(email);
    res.fold(
      (f) => emit((status: FormStatus.failure, message: f.message)),
      (_) => emit((
        status: FormStatus.success,
        message: 'أعدنا إرسال رسالة التحقق، تفقّد بريدك'
      )),
    );
  }
}
