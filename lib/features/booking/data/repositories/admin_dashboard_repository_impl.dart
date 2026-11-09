import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/admin_dashboard_data.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_data_source.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl(this._remote);

  final AdminDashboardRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AdminAppointment>>> getAppointments({
    required DateTime from,
    required DateTime until,
  }) =>
      _guard(() => _remote.getAppointments(from: from, until: until));

  @override
  Future<Either<Failure, List<AdminAppointment>>> getScheduleConflicts() =>
      _guard(_remote.getScheduleConflicts);

  @override
  Future<Either<Failure, List<AdminChangeRequest>>> getPendingChangeRequests() =>
      _guard(_remote.getPendingChangeRequests);

  @override
  Future<Either<Failure, Unit>> decideChangeRequest({
    required String requestId,
    required bool approve,
    DateTime? newStartsAt,
    String? note,
  }) =>
      _guard(() async {
        await _remote.decideChangeRequest(
          requestId: requestId,
          approve: approve,
          newStartsAt: newStartsAt,
          note: note,
        );
        return unit;
      });

  @override
  Future<Either<Failure, List<AdminStudent>>> getStudents() =>
      _guard(_remote.getStudents);

  @override
  Future<Either<Failure, List<AvailabilityRule>>> getAvailabilityRules() =>
      _guard(_remote.getAvailabilityRules);

  @override
  Future<Either<Failure, Unit>> saveAvailabilityRule({
    String? id,
    required int weekday,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    required bool isActive,
  }) =>
      _guard(() async {
        await _remote.saveAvailabilityRule(
          id: id,
          weekday: weekday,
          startTime: startTime,
          endTime: endTime,
          slotMinutes: slotMinutes,
          isActive: isActive,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteAvailabilityRule(String id) =>
      _guard(() async {
        await _remote.deleteAvailabilityRule(id);
        return unit;
      });

  @override
  Future<Either<Failure, List<AvailabilityException>>>
      getAvailabilityExceptions() =>
          _guard(_remote.getAvailabilityExceptions);

  @override
  Future<Either<Failure, Unit>> saveAvailabilityException({
    String? id,
    required DateTime date,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
  }) =>
      _guard(() async {
        await _remote.saveAvailabilityException(
          id: id,
          date: date,
          type: type,
          startTime: startTime,
          endTime: endTime,
          reason: reason,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteAvailabilityException(String id) =>
      _guard(() async {
        await _remote.deleteAvailabilityException(id);
        return unit;
      });

  @override
  Future<Either<Failure, AdminAppSettings>> getAppSettings() =>
      _guard(_remote.getAppSettings);

  @override
  Future<Either<Failure, Unit>> updateAppSettings(AdminAppSettings settings) =>
      _guard(() async {
        await _remote.updateAppSettings(settings);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> createAppointment({
    required String studentId,
    required DateTime startsAt,
    required int minutes,
    String? note,
  }) =>
      _guard(() async {
        await _remote.createAppointment(
          studentId: studentId,
          startsAt: startsAt,
          minutes: minutes,
          note: note,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> updateAppointment({
    required String id,
    required DateTime newStartsAt,
    String? reason,
  }) =>
      _guard(() async {
        await _remote.updateAppointment(
          id: id,
          newStartsAt: newStartsAt,
          reason: reason,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> cancelAppointment({
    required String id,
    String? reason,
  }) =>
      _guard(() async {
        await _remote.cancelAppointment(id: id, reason: reason);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setAttendance({
    required String id,
    required String outcome,
  }) =>
      _guard(() async {
        await _remote.setAttendance(id: id, outcome: outcome);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on PostgrestException catch (error) {
      return Left(ServerFailure(_message(error.message)));
    } on AuthException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(_message(error.toString())));
    }
  }

  String _message(String raw) {
    if (raw.contains('slot_unavailable')) {
      return 'هذا الوقت محجوز بالفعل. اختر وقتاً آخر.';
    }
    if (raw.contains('invalid_state')) {
      return 'تغيرت حالة الموعد. حدّث البيانات وحاول مجدداً.';
    }
    if (raw.contains('not_found')) return 'العنصر المطلوب غير موجود.';
    if (raw.contains('forbidden')) return 'لا تملك صلاحية تنفيذ هذا الإجراء.';
    if (raw.contains('too_early')) return 'لا يمكن تسجيل الحضور قبل بدء الموعد.';
    if (raw.contains('invalid_outcome')) return 'حالة الحضور المحددة غير صحيحة.';
    return raw;
  }
}
