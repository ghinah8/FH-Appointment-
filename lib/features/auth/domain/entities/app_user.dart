import 'package:equatable/equatable.dart';

enum UserRole { student, admin }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.emailConfirmed,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool emailConfirmed;

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [id, email, fullName, role, emailConfirmed];
}
