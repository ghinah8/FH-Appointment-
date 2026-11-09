import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/admin_dashboard_data.dart';
import '../../domain/usecases/admin_dashboard_usecases.dart';

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.isLoading = true,
    this.isBusy = false,
    this.error,
    this.message,
    this.appointments = const [],
    this.conflicts = const [],
    this.changeRequests = const [],
    this.students = const [],
    this.rules = const [],
    this.exceptions = const [],
    this.settings,
  });

  final bool isLoading;
  final bool isBusy;
  final String? error;
  final String? message;
  final List<AdminAppointment> appointments;
  final List<AdminAppointment> conflicts;
  final List<AdminChangeRequest> changeRequests;
  final List<AdminStudent> students;
  final List<AvailabilityRule> rules;
  final List<AvailabilityException> exceptions;
  final AdminAppSettings? settings;

  AdminDashboardState copyWith({
    bool? isLoading,
    bool? isBusy,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
    List<AdminAppointment>? appointments,
    List<AdminAppointment>? conflicts,
    List<AdminChangeRequest>? changeRequests,
    List<AdminStudent>? students,
    List<AvailabilityRule>? rules,
    List<AvailabilityException>? exceptions,
    AdminAppSettings? settings,
  }) =>
      AdminDashboardState(
        isLoading: isLoading ?? this.isLoading,
        isBusy: isBusy ?? this.isBusy,
        error: clearError ? null : error ?? this.error,
        message: clearMessage ? null : message ?? this.message,
        appointments: appointments ?? this.appointments,
        conflicts: conflicts ?? this.conflicts,
        changeRequests: changeRequests ?? this.changeRequests,
        students: students ?? this.students,
        rules: rules ?? this.rules,
        exceptions: exceptions ?? this.exceptions,
        settings: settings ?? this.settings,
      );

  @override
  List<Object?> get props => [
        isLoading,
        isBusy,
        error,
        message,
        appointments,
        conflicts,
        changeRequests,
        students,
        rules,
        exceptions,
        settings,
      ];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._actions) : super(const AdminDashboardState());

  final AdminDashboardUseCases _actions;

  DateTime get _from => DateTime.now().subtract(const Duration(days: 30));
  DateTime get _until => DateTime.now().add(const Duration(days: 90));

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    await Future.wait([
      loadAppointments(),
      loadConflicts(),
      loadChangeRequests(),
      loadStudents(),
      loadAvailability(),
      loadSettings(),
    ]);
    emit(state.copyWith(isLoading: false));
  }

  Future<void> loadAppointments() async {
    final result = await _actions.appointments(from: _from, until: _until);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (appointments) => emit(state.copyWith(appointments: appointments)),
    );
  }

  Future<void> loadConflicts() async {
    final result = await _actions.scheduleConflicts();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (conflicts) => emit(state.copyWith(conflicts: conflicts)),
    );
  }

  Future<void> loadChangeRequests() async {
    final result = await _actions.changeRequests();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (requests) => emit(state.copyWith(changeRequests: requests)),
    );
  }

  Future<void> loadStudents() async {
    final result = await _actions.students();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (students) => emit(state.copyWith(students: students)),
    );
  }

  Future<void> loadAvailability() async {
    final rulesResult = await _actions.availabilityRules();
    rulesResult.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (rules) => emit(state.copyWith(rules: rules)),
    );
    final exceptionsResult = await _actions.exceptions();
    exceptionsResult.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (exceptions) => emit(state.copyWith(exceptions: exceptions)),
    );
  }

  Future<void> loadSettings() async {
    final result = await _actions.settings();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (settings) => emit(state.copyWith(settings: settings)),
    );
  }

  Future<bool> decideChangeRequest({
    required AdminChangeRequest request,
    required bool approve,
    DateTime? newStartsAt,
    String? note,
  }) async =>
      _act(
        () => _actions.decideChangeRequest(
          requestId: request.id,
          approve: approve,
          newStartsAt: newStartsAt,
          note: note,
        ),
        refreshRequestsAndAppointments,
      );

  Future<bool> saveRule({
    String? id,
    required int weekday,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    required bool isActive,
  }) async =>
      _act(
        () => _actions.saveRule(
          id: id,
          weekday: weekday,
          startTime: startTime,
          endTime: endTime,
          slotMinutes: slotMinutes,
          isActive: isActive,
        ),
        refreshAvailabilityAndConflicts,
      );

  Future<bool> deleteRule(String id) async =>
      _act(() => _actions.deleteRule(id), refreshAvailabilityAndConflicts);

  Future<bool> saveException({
    String? id,
    required DateTime date,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
  }) async =>
      _act(
        () => _actions.saveException(
          id: id,
          date: date,
          type: type,
          startTime: startTime,
          endTime: endTime,
          reason: reason,
        ),
        refreshAvailabilityAndConflicts,
      );

  Future<bool> deleteException(String id) async =>
      _act(() => _actions.deleteException(id), refreshAvailabilityAndConflicts);

  Future<bool> updateSettings(AdminAppSettings settings) async =>
      _act(() => _actions.updateSettings(settings), loadSettings);

  Future<bool> createAppointment({
    required String studentId,
    required DateTime startsAt,
    required int minutes,
    String? note,
  }) async =>
      _act(
        () => _actions.createAppointment(
          studentId: studentId,
          startsAt: startsAt,
          minutes: minutes,
          note: note,
        ),
        refreshAppointmentsAndStudents,
      );

  Future<bool> updateAppointment({
    required String id,
    required DateTime newStartsAt,
    String? reason,
  }) async =>
      _act(
        () => _actions.updateAppointment(
          id: id,
          newStartsAt: newStartsAt,
          reason: reason,
        ),
        refreshCalendarData,
      );

  Future<bool> cancelAppointment({required String id, String? reason}) async =>
      _act(
        () => _actions.cancelAppointment(id: id, reason: reason),
        refreshCalendarData,
      );

  Future<bool> setAttendance({
    required String id,
    required String outcome,
  }) async =>
      _act(
        () => _actions.setAttendance(id: id, outcome: outcome),
        refreshCalendarData,
      );

  Future<void> refreshRequestsAndAppointments() async {
    await Future.wait([loadChangeRequests(), refreshCalendarData()]);
  }

  Future<void> refreshAvailabilityAndConflicts() async {
    await Future.wait([loadAvailability(), loadConflicts()]);
  }

  Future<void> refreshAppointmentsAndStudents() async {
    await Future.wait([refreshCalendarData(), loadStudents()]);
  }

  Future<void> refreshCalendarData() async {
    await Future.wait([loadAppointments(), loadConflicts()]);
  }

  Future<bool> _act(
    Future<Either<Failure, Unit>> Function() action,
    Future<void> Function() refresh,
  ) async {
    emit(state.copyWith(isBusy: true, clearError: true, clearMessage: true));
    final result = await action();
    final succeeded = result.fold(
      (failure) {
        emit(state.copyWith(isBusy: false, error: failure.message));
        return false;
      },
      (_) => true,
    );
    if (!succeeded) return false;
    await refresh();
    emit(state.copyWith(
      isBusy: false,
      message: 'تم حفظ التغييرات بنجاح',
    ));
    return true;
  }
}
