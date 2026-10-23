import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/booking_usecases.dart';
import 'appointments_state.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit({
    required GetMyAppointments getMyAppointments,
  })  : _getMyAppointments = getMyAppointments,
        super(const AppointmentsState());

  final GetMyAppointments _getMyAppointments;

  Future<void> loadAppointments() async {
    emit(state.copyWith(
      isLoading: true,
      clearMessage: true,
      isError: false,
    ));

    final result = await _getMyAppointments(const NoParams());

    result.fold(
      (failure) {
        debugPrint('MY APPOINTMENTS ERROR: ${failure.message}');

        emit(state.copyWith(
          isLoading: false,
          message: failure.message,
          isError: true,
        ));
      },
      (appointments) {
        debugPrint('MY APPOINTMENTS COUNT: ${appointments.length}');

        emit(state.copyWith(
          appointments: appointments,
          isLoading: false,
          clearMessage: true,
          isError: false,
        ));
      },
    );
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();

    return state.appointments.where((appointment) {
      return appointment.endsAt.isAfter(now) &&
          (appointment.status == 'pending' ||
              appointment.status == 'confirmed' ||
              appointment.status == 'cancellation_requested' ||
              appointment.status == 'reschedule_requested');
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();

    return state.appointments.where((appointment) {
      return appointment.endsAt.isBefore(now) ||
          appointment.status == 'rejected' ||
          appointment.status == 'cancelled' ||
          appointment.status == 'completed' ||
          appointment.status == 'no_show' ||
          appointment.status == 'expired';
    }).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }
}
