import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../entities/study_year_option.dart';
import '../entities/university.dart';

class SignUpData {
  const SignUpData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.universityId,
    required this.studyYear,
  });

  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String universityId;
  final StudyYearOption studyYear;
}

abstract class AuthRepository {
  /// يُطلق حدثاً عند أي تغيّر في الجلسة (دخول/خروج/تحديث).
  Stream<void> get onAuthChanged;

  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, Unit>> signIn({
    required String email,
    required String password,
  });

  /// يعيد true إذا كان الحساب بحاجة إلى التحقق من البريد قبل المتابعة.
  Future<Either<Failure, bool>> signUp(SignUpData data);

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, List<University>>> getUniversities();

  Future<Either<Failure, Unit>> resendVerification(String email);

  Future<Either<Failure, Unit>> sendPasswordReset(String email);
}
