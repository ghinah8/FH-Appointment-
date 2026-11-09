import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_appointment.dart';
import '../entities/admin_dashboard_data.dart';

abstract class AdminDashboardRepository {
  Future<Either<Failure, List<AdminAppointment>>> getAppointments({
    required DateTime from,
    required DateTime until,
  });

  Future<Either<Failure, List<AdminAppointment>>> getScheduleConflicts();

  Future<Either<Failure, List<AdminChangeRequest>>> getPendingChangeRequests();

  Future<Either<Failure, Unit>> decideChangeRequest({
    required String requestId,
    required bool approve,
    DateTime? newStartsAt,
    String? note,
  });

  Future<Either<Failure, List<AdminStudent>>> getStudents();

  Future<Either<Failure, List<AvailabilityRule>>> getAvailabilityRules();

  Future<Either<Failure, Unit>> saveAvailabilityRule({
    String? id,
    required int weekday,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    required bool isActive,
  });

  Future<Either<Failure, Unit>> deleteAvailabilityRule(String id);

  Future<Either<Failure, List<AvailabilityException>>> getAvailabilityExceptions();

  Future<Either<Failure, Unit>> saveAvailabilityException({
    String? id,
    required DateTime date,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
  });

  Future<Either<Failure, Unit>> deleteAvailabilityException(String id);

  Future<Either<Failure, AdminAppSettings>> getAppSettings();

  Future<Either<Failure, Unit>> updateAppSettings(AdminAppSettings settings);

  Future<Either<Failure, Unit>> createAppointment({
    required String studentId,
    required DateTime startsAt,
    required int minutes,
    String? note,
  });

  Future<Either<Failure, Unit>> updateAppointment({
    required String id,
    required DateTime newStartsAt,
    String? reason,
  });

  Future<Either<Failure, Unit>> cancelAppointment({
    required String id,
    String? reason,
  });

  Future<Either<Failure, Unit>> setAttendance({
    required String id,
    required String outcome,
  });
}
