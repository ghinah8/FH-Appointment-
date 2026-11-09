import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fatima_habib/core/error/failures.dart';
import 'package:fatima_habib/features/auth/domain/entities/app_user.dart';
import 'package:fatima_habib/features/booking/domain/entities/admin_appointment.dart';
import 'package:fatima_habib/features/booking/domain/entities/admin_dashboard_data.dart';
import 'package:fatima_habib/features/booking/domain/repositories/booking_repository.dart';
import 'package:fatima_habib/features/booking/domain/repositories/admin_dashboard_repository.dart';
import 'package:fatima_habib/features/booking/domain/usecases/booking_usecases.dart';
import 'package:fatima_habib/features/booking/domain/usecases/admin_dashboard_usecases.dart';
import 'package:fatima_habib/features/booking/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:fatima_habib/features/booking/presentation/cubit/appointments_admin_cubit.dart';
import 'package:fatima_habib/features/booking/presentation/pages/admin_home_page.dart';

class _MockBookingRepository extends Mock implements BookingRepository {}
class _MockAdminDashboardRepository extends Mock implements AdminDashboardRepository {}
class _FakeDateTime extends Fake implements DateTime {}

const _admin = AppUser(
  id: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Widget Admin',
  role: UserRole.admin,
  emailConfirmed: true,
);

final _appointment = AdminAppointment(
  id: 'appointment-1',
  studentId: 'student-1',
  studentName: 'Widget Student',
  startsAt: DateTime(2026, 11, 10, 11),
  endsAt: DateTime(2026, 11, 10, 12),
  status: 'pending',
);

final _sl = GetIt.instance;

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'en_US';
    registerFallbackValue(_FakeDateTime());
  });
  setUp(() async => _sl.reset());
  tearDown(() async => _sl.reset());

  testWidgets('shows pending appointment details', (tester) async {
    final repository = _repositoryWithPending([_appointment]);
    await _pumpAdminHome(tester, repository);

    expect(find.text('Widget Student'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('shows empty state when there are no pending appointments',
      (tester) async {
    final repository = _repositoryWithPending([]);
    await _pumpAdminHome(tester, repository);

    expect(find.text('Widget Student'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('allows retry after loading fails', (tester) async {
    final repository = _MockBookingRepository();
    var requestCount = 0;
    when(() => repository.getPendingAppointments()).thenAnswer((_) async {
      if (requestCount++ == 0) {
        return const Left(ServerFailure('Could not load appointments'));
      }
      return Right([_appointment]);
    });

    await _pumpAdminHome(tester, repository);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('Widget Student'), findsOneWidget);
  });

  testWidgets('accepts a pending appointment from its card', (tester) async {
    final repository = _repositoryWithPending([_appointment]);
    when(
      () => repository.decideAppointment(
        appointmentId: any(named: 'appointmentId'),
        confirm: any(named: 'confirm'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    await _pumpAdminHome(tester, repository);
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('Widget Student'), findsNothing);
    verify(
      () => repository.decideAppointment(
        appointmentId: _appointment.id,
        confirm: true,
        note: null,
      ),
    ).called(1);
  });
}

_MockBookingRepository _repositoryWithPending(
  List<AdminAppointment> appointments,
) {
  final repository = _MockBookingRepository();
  when(() => repository.getPendingAppointments())
      .thenAnswer((_) async => Right(appointments));
  return repository;
}

Future<void> _pumpAdminHome(
  WidgetTester tester,
  BookingRepository repository,
) async {
  final cubit = AppointmentsAdminCubit(
    getPendingAppointments: GetPendingAppointments(repository),
    decideAppointment: DecideAppointment(repository),
  );
  _sl.registerFactory<AppointmentsAdminCubit>(() => cubit);
  final adminRepository = _MockAdminDashboardRepository();
  when(() => adminRepository.getAppointments(
        from: any(named: 'from'),
        until: any(named: 'until'),
      )).thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getScheduleConflicts())
      .thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getPendingChangeRequests())
      .thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getStudents())
      .thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getAvailabilityRules())
      .thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getAvailabilityExceptions())
      .thenAnswer((_) async => const Right([]));
  when(() => adminRepository.getAppSettings()).thenAnswer((_) async =>
      const Right(AdminAppSettings(
        locationAddress: '',
        locationMapsUrl: null,
        bookingHorizonDays: 7,
        pendingHoldHours: 24,
        lessonDurationLabel: '60 دقيقة',
      )));
  _sl.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(AdminDashboardUseCases(adminRepository)),
  );

  await tester.pumpWidget(
    const MaterialApp(home: AdminHomePage(user: _admin)),
  );
  await tester.pump();
  await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
  await tester.pumpAndSettle();
}
