import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_appointment.dart';
import '../entities/appointment.dart';
import '../entities/available_slot.dart';
import '../repositories/booking_repository.dart';

class GetAvailableSlots implements UseCase<List<AvailableSlot>, NoParams> {
  GetAvailableSlots(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, List<AvailableSlot>>> call(NoParams params) {
    return _repository.getAvailableSlots();
  }
}

class RequestAppointment implements UseCase<Unit, DateTime> {
  RequestAppointment(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DateTime startsAt) {
    return _repository.requestAppointment(startsAt);
  }
}

class GetMyAppointments implements UseCase<List<Appointment>, NoParams> {
  GetMyAppointments(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, List<Appointment>>> call(NoParams params) {
    return _repository.getMyAppointments();
  }
}

class GetPendingAppointments
    implements UseCase<List<AdminAppointment>, NoParams> {
  GetPendingAppointments(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, List<AdminAppointment>>> call(NoParams params) {
    return _repository.getPendingAppointments();
  }
}

class DecideAppointment implements UseCase<Unit, DecideAppointmentParams> {
  DecideAppointment(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DecideAppointmentParams params) {
    return _repository.decideAppointment(
      appointmentId: params.appointmentId,
      confirm: params.confirm,
      note: params.note,
    );
  }
}

class DecideAppointmentParams {
  const DecideAppointmentParams({
    required this.appointmentId,
    required this.confirm,
    this.note,
  });

  final String appointmentId;
  final bool confirm;
  final String? note;
}
