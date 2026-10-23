import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/usecases/booking_usecases.dart';

abstract class AppointmentsAdminState {
  const AppointmentsAdminState();
}

class AppointmentsAdminInitial extends AppointmentsAdminState {
  const AppointmentsAdminInitial();
}

class AppointmentsAdminLoading extends AppointmentsAdminState {
  const AppointmentsAdminLoading();
}

class AppointmentsAdminLoaded extends AppointmentsAdminState {
  const AppointmentsAdminLoaded(this.appointments);

  final List<AdminAppointment> appointments;
}

class AppointmentsAdminError extends AppointmentsAdminState {
  const AppointmentsAdminError(this.message);

  final String message;
}

class AppointmentsAdminActionLoading extends AppointmentsAdminState {
  const AppointmentsAdminActionLoading(this.appointments, this.appointmentId);

  final List<AdminAppointment> appointments;
  final String appointmentId;
}

class AppointmentsAdminCubit extends Cubit<AppointmentsAdminState> {
  AppointmentsAdminCubit({
    required GetPendingAppointments getPendingAppointments,
    required DecideAppointment decideAppointment,
  })  : _getPendingAppointments = getPendingAppointments,
        _decideAppointment = decideAppointment,
        super(const AppointmentsAdminInitial());

  final GetPendingAppointments _getPendingAppointments;
  final DecideAppointment _decideAppointment;

  Future<void> loadPendingAppointments() async {
    emit(const AppointmentsAdminLoading());

    final result = await _getPendingAppointments(const NoParams());
    result.fold(
      (failure) => emit(AppointmentsAdminError(failure.message)),
      (appointments) => emit(AppointmentsAdminLoaded(appointments)),
    );
  }

  Future<bool> decide({
    required AdminAppointment appointment,
    required bool confirm,
    String? note,
  }) async {
    final currentState = state;
    final appointments = currentState is AppointmentsAdminLoaded
        ? currentState.appointments
        : currentState is AppointmentsAdminActionLoading
            ? currentState.appointments
            : <AdminAppointment>[];

    emit(AppointmentsAdminActionLoading(appointments, appointment.id));

    final result = await _decideAppointment(
      DecideAppointmentParams(
        appointmentId: appointment.id,
        confirm: confirm,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
      ),
    );

    return result.fold(
      (failure) {
        emit(AppointmentsAdminError(failure.message));
        return false;
      },
      (_) {
        emit(
          AppointmentsAdminLoaded(
            appointments.where((item) => item.id != appointment.id).toList(),
          ),
        );
        return true;
      },
    );
  }
}
