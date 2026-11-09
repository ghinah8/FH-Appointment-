import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fatima_habib/core/error/failures.dart';
import 'package:fatima_habib/features/booking/domain/entities/admin_appointment.dart';
import 'package:fatima_habib/features/booking/domain/repositories/booking_repository.dart';
import 'package:fatima_habib/features/booking/domain/usecases/booking_usecases.dart';
import 'package:fatima_habib/features/booking/presentation/cubit/appointments_admin_cubit.dart';

class _MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  test('retains loaded appointments when refreshing fails', () async {
    final repository = _MockBookingRepository();
    final appointment = AdminAppointment(
      id: 'appointment-1',
      studentId: 'student-1',
      studentName: 'Student',
      startsAt: DateTime(2026, 11, 10, 11),
      endsAt: DateTime(2026, 11, 10, 12),
      status: 'pending',
    );
    var requestCount = 0;

    when(() => repository.getPendingAppointments()).thenAnswer((_) async {
      if (requestCount++ == 0) {
        return Right([appointment]);
      }
      return const Left(ServerFailure('Could not refresh appointments'));
    });

    final cubit = AppointmentsAdminCubit(
      getPendingAppointments: GetPendingAppointments(repository),
      decideAppointment: DecideAppointment(repository),
    );

    await cubit.loadPendingAppointments();
    expect(cubit.state, isA<AppointmentsAdminLoaded>());

    await cubit.loadPendingAppointments();
    expect(cubit.state, isA<AppointmentsAdminError>());
    expect(
      (cubit.state as AppointmentsAdminError).appointments,
      [appointment],
    );

    await cubit.close();
  });
}
