import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.studentNote,
    this.adminNote,
    this.isExceptional = false,
    this.expiresAt,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String? studentNote;
  final String? adminNote;
  final bool isExceptional;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [
        id,
        startsAt,
        endsAt,
        status,
        studentNote,
        adminNote,
        isExceptional,
        expiresAt,
      ];
}
