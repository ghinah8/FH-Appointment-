import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_appointment.dart';
import '../entities/appointment.dart';
import '../entities/available_slot.dart';

abstract class BookingRepository {
  Future<Either<Failure, List<AvailableSlot>>> getAvailableSlots();

  Future<Either<Failure, Unit>> requestAppointment(DateTime startsAt);

  Future<Either<Failure, List<Appointment>>> getMyAppointments();

  Future<Either<Failure, List<AdminAppointment>>> getPendingAppointments();

  Future<Either<Failure, Unit>> decideAppointment({
    required String appointmentId,
    required bool confirm,
    String? note,
  });
}
