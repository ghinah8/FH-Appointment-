import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/available_slot.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Appointment>>> getMyAppointments() async {
    try {
      return Right(await _remote.getMyAppointments());
    } catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, List<AvailableSlot>>> getAvailableSlots() async {
    try {
      return Right(await _remote.getAvailableSlots());
    } catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestAppointment(DateTime startsAt) async {
    try {
      await _remote.requestAppointment(startsAt);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, List<AdminAppointment>>>
      getPendingAppointments() async {
    try {
      return Right(await _remote.getPendingAppointments());
    } catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> decideAppointment({
    required String appointmentId,
    required bool confirm,
    String? note,
  }) async {
    try {
      await _remote.decideAppointment(
        appointmentId: appointmentId,
        confirm: confirm,
        note: note,
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  String _message(Object error) {
    final value = error.toString();

    if (value.contains('slot_unavailable')) {
      return 'هذا الموعد لم يعد متاحاً. حدّث القائمة واختر موعداً آخر.';
    }

    if (value.contains('email_not_verified')) {
      return 'يجب تأكيد البريد الإلكتروني قبل طلب الحجز.';
    }

    if (value.contains('not_authenticated')) {
      return 'انتهت الجلسة. سجّل الدخول من جديد.';
    }

    if (value.contains('existing_appointment_request')) {
      return 'اترك دور لغيرك 3> ,لديك طلب حجز قائم بالفعل. لا يمكنك طلب موعد جديد حالياً.';
    }

    if (value.contains('forbidden')) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }

    if (value.contains('invalid_state')) {
      return 'تم تحديث حالة الطلب مسبقاً. حدّث القائمة وحاول مجدداً.';
    }

    if (value.contains('not_found')) {
      return 'طلب الحجز غير موجود.';
    }

    return 'تعذّر تنفيذ العملية. تحقق من الاتصال وحاول مرة أخرى.';
  }
}
