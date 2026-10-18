import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Stream<void> get onAuthChanged => _remote.onAuthChanged;

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() =>
      _guard(() => _remote.getCurrentUser());

  @override
  Future<Either<Failure, Unit>> signIn({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        await _remote.signIn(email, password);
        return unit;
      });

  @override
  Future<Either<Failure, bool>> signUp(SignUpData data) =>
      _guard(() => _remote.signUp(data));

  @override
  Future<Either<Failure, Unit>> signOut() => _guard(() async {
        await _remote.signOut();
        return unit;
      });

  @override
  Future<Either<Failure, List<University>>> getUniversities() =>
      _guard(() => _remote.getUniversities());

  @override
  Future<Either<Failure, Unit>> resendVerification(String email) =>
      _guard(() async {
        await _remote.resendVerification(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      _guard(() async {
        await _remote.sendPasswordReset(email);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on AuthException catch (e) {
      return Left(_mapAuth(e));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  AuthFailure _mapAuth(AuthException e) {
    final code = (e.code ?? '').toLowerCase();
    final msg = e.message.toLowerCase();

    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return const AuthFailure(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        code: AuthFailureCode.invalidCredentials,
      );
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return const AuthFailure(
        'لم يتم تفعيل الحساب بعد، تحقق من بريدك الإلكتروني',
        code: AuthFailureCode.emailNotConfirmed,
      );
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return const AuthFailure(
        'هذا البريد الإلكتروني مسجّل مسبقاً',
        code: AuthFailureCode.userExists,
      );
    }
    if (code == 'weak_password' || msg.contains('password')) {
      return const AuthFailure(
        'كلمة المرور ضعيفة، استخدم 8 أحرف على الأقل',
        code: AuthFailureCode.weakPassword,
      );
    }
    if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
      return const AuthFailure('محاولات كثيرة، انتظر قليلاً ثم أعد المحاولة');
    }
    return const AuthFailure('تعذّر إكمال العملية، حاول مرة أخرى');
  }
}
