import '../../domain/entities/app_user.dart';
import '../../domain/entities/university.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.emailConfirmed,
  });

  factory AppUserModel.fromSupabase({
    required String id,
    required String? email,
    required String? emailConfirmedAt,
    Map<String, dynamic>? profile,
  }) {
    return AppUserModel(
      id: id,
      email: email ?? '',
      fullName: (profile?['full_name'] as String?) ?? '',
      role: profile?['role'] == 'admin' ? UserRole.admin : UserRole.student,
      emailConfirmed: emailConfirmedAt != null,
    );
  }
}

class UniversityModel extends University {
  const UniversityModel({required super.id, required super.name});

  factory UniversityModel.fromJson(Map<String, dynamic> json) =>
      UniversityModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
