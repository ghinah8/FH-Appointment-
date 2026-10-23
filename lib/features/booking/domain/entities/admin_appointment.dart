import 'package:equatable/equatable.dart';

class AdminAppointment extends Equatable {
  const AdminAppointment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.studentPhone,
    this.universityName,
    this.studyYear,
    this.isGraduating = false,
    this.studentNote,
    this.adminNote,
    this.isExceptional = false,
    this.expiresAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String? studentPhone;
  final String? universityName;
  final String? studyYear;
  final bool isGraduating;
  final String? studentNote;
  final String? adminNote;
  final bool isExceptional;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        startsAt,
        endsAt,
        status,
        studentPhone,
        universityName,
        studyYear,
        isGraduating,
        studentNote,
        adminNote,
        isExceptional,
        expiresAt,
      ];
}
