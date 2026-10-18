import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../entities/university.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser implements UseCase<AppUser?, NoParams> {
  GetCurrentUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AppUser?>> call(NoParams _) => _repo.getCurrentUser();
}

class SignInParams {
  const SignInParams({required this.email, required this.password});
  final String email;
  final String password;
}

class SignIn implements UseCase<Unit, SignInParams> {
  SignIn(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(SignInParams p) =>
      _repo.signIn(email: p.email.trim(), password: p.password);
}

class SignUp implements UseCase<bool, SignUpData> {
  SignUp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, bool>> call(SignUpData data) => _repo.signUp(data);
}

class SignOut implements UseCase<Unit, NoParams> {
  SignOut(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.signOut();
}

class GetUniversities implements UseCase<List<University>, NoParams> {
  GetUniversities(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, List<University>>> call(NoParams _) =>
      _repo.getUniversities();
}

class ResendVerification implements UseCase<Unit, String> {
  ResendVerification(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repo.resendVerification(email.trim());
}

class SendPasswordReset implements UseCase<Unit, String> {
  SendPasswordReset(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repo.sendPasswordReset(email.trim());
}
