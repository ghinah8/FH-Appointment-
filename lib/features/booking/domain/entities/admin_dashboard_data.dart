import 'package:equatable/equatable.dart';

class AdminStudent extends Equatable {
  const AdminStudent({
    required this.id,
    required this.fullName,
    this.phone,
    this.universityName,
    this.studyYear,
    this.isGraduating = false,
    this.appointmentsCount = 0,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? universityName;
  final String? studyYear;
  final bool isGraduating;
  final int appointmentsCount;

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        universityName,
        studyYear,
        isGraduating,
        appointmentsCount,
      ];
}

class AdminChangeRequest extends Equatable {
  const AdminChangeRequest({
    required this.id,
    required this.appointmentId,
    required this.studentName,
    required this.type,
    required this.createdAt,
    required this.currentStartsAt,
    required this.currentEndsAt,
    this.phone,
    this.universityName,
    this.reason,
    this.requestedStartsAt,
  });

  final String id;
  final String appointmentId;
  final String studentName;
  final String type;
  final DateTime createdAt;
  final DateTime currentStartsAt;
  final DateTime currentEndsAt;
  final String? phone;
  final String? universityName;
  final String? reason;
  final DateTime? requestedStartsAt;

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        studentName,
        type,
        createdAt,
        currentStartsAt,
        currentEndsAt,
        phone,
        universityName,
        reason,
        requestedStartsAt,
      ];
}

class AvailabilityRule extends Equatable {
  const AvailabilityRule({
    required this.id,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.slotMinutes,
    required this.isActive,
  });

  final String id;
  final int weekday;
  final String startTime;
  final String endTime;
  final int slotMinutes;
  final bool isActive;

  @override
  List<Object?> get props => [id, weekday, startTime, endTime, slotMinutes, isActive];
}

class AvailabilityException extends Equatable {
  const AvailabilityException({
    required this.id,
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
    this.reason,
  });

  final String id;
  final DateTime date;
  final String type;
  final String? startTime;
  final String? endTime;
  final String? reason;

  @override
  List<Object?> get props => [id, date, type, startTime, endTime, reason];
}

class AdminAppSettings extends Equatable {
  const AdminAppSettings({
    required this.locationAddress,
    required this.locationMapsUrl,
    required this.bookingHorizonDays,
    required this.pendingHoldHours,
    required this.lessonDurationLabel,
  });

  final String locationAddress;
  final String? locationMapsUrl;
  final int bookingHorizonDays;
  final int pendingHoldHours;
  final String lessonDurationLabel;

  @override
  List<Object?> get props => [
        locationAddress,
        locationMapsUrl,
        bookingHorizonDays,
        pendingHoldHours,
        lessonDurationLabel,
      ];
}
