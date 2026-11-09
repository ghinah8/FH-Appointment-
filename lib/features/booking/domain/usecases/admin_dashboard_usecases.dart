import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_appointment.dart';
import '../entities/admin_dashboard_data.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Application actions used by the admin dashboard presentation layer.
class AdminDashboardUseCases {
  const AdminDashboardUseCases(this._repository);

  final AdminDashboardRepository _repository;

  Future<Either<Failure, List<AdminAppointment>>> appointments({
    required DateTime from,
    required DateTime until,
  }) =>
      _repository.getAppointments(from: from, until: until);

  Future<Either<Failure, List<AdminAppointment>>> scheduleConflicts() =>
      _repository.getScheduleConflicts();

  Future<Either<Failure, List<AdminChangeRequest>>> changeRequests() =>
      _repository.getPendingChangeRequests();

  Future<Either<Failure, Unit>> decideChangeRequest({
    required String requestId,
    required bool approve,
    DateTime? newStartsAt,
    String? note,
  }) =>
      _repository.decideChangeRequest(
        requestId: requestId,
        approve: approve,
        newStartsAt: newStartsAt,
        note: note,
      );

  Future<Either<Failure, List<AdminStudent>>> students() =>
      _repository.getStudents();

  Future<Either<Failure, List<AvailabilityRule>>> availabilityRules() =>
      _repository.getAvailabilityRules();

  Future<Either<Failure, Unit>> saveRule({
    String? id,
    required int weekday,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    required bool isActive,
  }) =>
      _repository.saveAvailabilityRule(
        id: id,
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        slotMinutes: slotMinutes,
        isActive: isActive,
      );

  Future<Either<Failure, Unit>> deleteRule(String id) =>
      _repository.deleteAvailabilityRule(id);

  Future<Either<Failure, List<AvailabilityException>>> exceptions() =>
      _repository.getAvailabilityExceptions();

  Future<Either<Failure, Unit>> saveException({
    String? id,
    required DateTime date,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
  }) =>
      _repository.saveAvailabilityException(
        id: id,
        date: date,
        type: type,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

  Future<Either<Failure, Unit>> deleteException(String id) =>
      _repository.deleteAvailabilityException(id);

  Future<Either<Failure, AdminAppSettings>> settings() =>
      _repository.getAppSettings();

  Future<Either<Failure, Unit>> updateSettings(AdminAppSettings settings) =>
      _repository.updateAppSettings(settings);

  Future<Either<Failure, Unit>> createAppointment({
    required String studentId,
    required DateTime startsAt,
    required int minutes,
    String? note,
  }) =>
      _repository.createAppointment(
        studentId: studentId,
        startsAt: startsAt,
        minutes: minutes,
        note: note,
      );

  Future<Either<Failure, Unit>> updateAppointment({
    required String id,
    required DateTime newStartsAt,
    String? reason,
  }) =>
      _repository.updateAppointment(
        id: id,
        newStartsAt: newStartsAt,
        reason: reason,
      );

  Future<Either<Failure, Unit>> cancelAppointment({
    required String id,
    String? reason,
  }) =>
      _repository.cancelAppointment(id: id, reason: reason);

  Future<Either<Failure, Unit>> setAttendance({
    required String id,
    required String outcome,
  }) =>
      _repository.setAttendance(id: id, outcome: outcome);
}
