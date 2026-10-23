import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';

class AppointmentsState extends Equatable {
  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.message,
    this.isError = false,
  });

  final List<Appointment> appointments;
  final bool isLoading;
  final String? message;
  final bool isError;

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [
        appointments,
        isLoading,
        message,
        isError,
      ];
}
