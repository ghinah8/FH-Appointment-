import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/admin_dashboard_data.dart';

class AdminDashboardRemoteDataSource {
  AdminDashboardRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AdminAppointment>> getAppointments({
    required DateTime from,
    required DateTime until,
  }) async {
    final rows = await _client
        .from('appointments')
        .select(
          'id, student_id, starts_at, ends_at, status, student_note, admin_note, '
          'is_exceptional, expires_at, student:profiles!appointments_student_id_fkey('
          'full_name, phone, study_year, is_graduating, university:universities(name))',
        )
        .gte('starts_at', from.toUtc().toIso8601String())
        .lt('starts_at', until.toUtc().toIso8601String())
        .order('starts_at');
    return (rows as List<dynamic>).map(_appointmentFromRow).toList();
  }

  Future<List<AdminAppointment>> getScheduleConflicts() async {
    final rows = await _client.rpc('get_schedule_conflicts') as List<dynamic>;
    if (rows.isEmpty) return const [];
    final ids = rows
        .map((value) => Map<String, dynamic>.from(value as Map)['student_id'] as String)
        .toSet()
        .toList();
    final profileRows = await _client
        .from('profiles')
        .select('id, full_name, phone, study_year, is_graduating, university:universities(name)')
        .inFilter('id', ids);
    final students = <String, Map<String, dynamic>>{};
    for (final value in profileRows as List<dynamic>) {
      final profile = Map<String, dynamic>.from(value as Map);
      students[profile['id'] as String] = profile;
    }
    return rows.map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return _appointmentFromRow({...row, 'student': students[row['student_id']]});
    }).toList();
  }

  Future<List<AdminChangeRequest>> getPendingChangeRequests() async {
    final rows = await _client
        .from('appointment_requests')
        .select(
          'id, appointment_id, student_id, type, requested_starts_at, reason, created_at, '
          'appointment:appointments!appointment_requests_appointment_id_fkey('
          'starts_at, ends_at), '
          'student:profiles!appointment_requests_student_id_fkey('
          'full_name, phone, university:universities(name))',
        )
        .eq('status', 'pending')
        .order('created_at');

    return (rows as List<dynamic>).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final appointment = _map(row['appointment']);
      final student = _map(row['student']);
      final university = _map(student['university']);
      return AdminChangeRequest(
        id: row['id'] as String,
        appointmentId: row['appointment_id'] as String,
        studentName: student['full_name'] as String? ?? 'طالب',
        phone: student['phone'] as String?,
        universityName: university['name'] as String?,
        type: row['type'] as String,
        reason: row['reason'] as String?,
        requestedStartsAt: row['requested_starts_at'] == null
            ? null
            : DateTime.parse(row['requested_starts_at'] as String).toLocal(),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        currentStartsAt:
            DateTime.parse(appointment['starts_at'] as String).toLocal(),
        currentEndsAt:
            DateTime.parse(appointment['ends_at'] as String).toLocal(),
      );
    }).toList();
  }

  Future<void> decideChangeRequest({
    required String requestId,
    required bool approve,
    DateTime? newStartsAt,
    String? note,
  }) async {
    await _client.rpc(
      'admin_decide_request',
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_new_starts_at': newStartsAt?.toUtc().toIso8601String(),
        'p_note': _clean(note),
      },
    );
  }

  Future<List<AdminStudent>> getStudents() async {
    final rows = await _client
        .from('profiles')
        .select(
          'id, full_name, phone, study_year, is_graduating, '
          'university:universities(name), '
          'appointments:appointments!appointments_student_id_fkey(count)',
        )
        .eq('role', 'student')
        .order('full_name');
    return (rows as List<dynamic>).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final university = _map(row['university']);
      final counts = row['appointments'] as List<dynamic>? ?? const [];
      final count = counts.isEmpty
          ? 0
          : (Map<String, dynamic>.from(counts.first as Map)['count'] as num?)
                  ?.toInt() ??
              0;
      return AdminStudent(
        id: row['id'] as String,
        fullName: row['full_name'] as String? ?? '',
        phone: row['phone'] as String?,
        universityName: university['name'] as String?,
        studyYear: row['study_year'] as String?,
        isGraduating: row['is_graduating'] as bool? ?? false,
        appointmentsCount: count,
      );
    }).toList();
  }

  Future<List<AvailabilityRule>> getAvailabilityRules() async {
    final rows = await _client
        .from('availability_rules')
        .select('id, weekday, start_time, end_time, slot_minutes, is_active')
        .order('weekday')
        .order('start_time');
    return (rows as List<dynamic>).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return AvailabilityRule(
        id: row['id'] as String,
        weekday: (row['weekday'] as num).toInt(),
        startTime: _time(row['start_time']),
        endTime: _time(row['end_time']),
        slotMinutes: (row['slot_minutes'] as num).toInt(),
        isActive: row['is_active'] as bool? ?? true,
      );
    }).toList();
  }

  Future<void> saveAvailabilityRule({
    String? id,
    required int weekday,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    required bool isActive,
  }) async {
    final values = {
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'slot_minutes': slotMinutes,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('availability_rules').insert(values);
    } else {
      await _client.from('availability_rules').update(values).eq('id', id);
    }
  }

  Future<void> deleteAvailabilityRule(String id) async {
    await _client.from('availability_rules').delete().eq('id', id);
  }

  Future<List<AvailabilityException>> getAvailabilityExceptions() async {
    final rows = await _client
        .from('availability_exceptions')
        .select('id, date, type, start_time, end_time, reason')
        .order('date');
    return (rows as List<dynamic>).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return AvailabilityException(
        id: row['id'] as String,
        date: DateTime.parse(row['date'] as String),
        type: row['type'] as String,
        startTime: row['start_time'] == null ? null : _time(row['start_time']),
        endTime: row['end_time'] == null ? null : _time(row['end_time']),
        reason: row['reason'] as String?,
      );
    }).toList();
  }

  Future<void> saveAvailabilityException({
    String? id,
    required DateTime date,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final values = <String, dynamic>{
      'date': _date(date),
      'type': type,
      'start_time': startTime,
      'end_time': endTime,
      'reason': _clean(reason),
    };
    if (id == null) {
      await _client.from('availability_exceptions').insert(values);
    } else {
      await _client
          .from('availability_exceptions')
          .update(values)
          .eq('id', id);
    }
  }

  Future<void> deleteAvailabilityException(String id) async {
    await _client.from('availability_exceptions').delete().eq('id', id);
  }

  Future<AdminAppSettings> getAppSettings() async {
    final row = await _client
        .from('app_settings')
        .select(
          'location_address, location_maps_url, booking_horizon_days, '
          'pending_hold_hours, lesson_duration_label',
        )
        .eq('id', 1)
        .single();
    return AdminAppSettings(
      locationAddress: row['location_address'] as String? ?? '',
      locationMapsUrl: row['location_maps_url'] as String?,
      bookingHorizonDays: (row['booking_horizon_days'] as num).toInt(),
      pendingHoldHours: (row['pending_hold_hours'] as num).toInt(),
      lessonDurationLabel: row['lesson_duration_label'] as String? ?? '',
    );
  }

  Future<void> updateAppSettings(AdminAppSettings settings) async {
    await _client.from('app_settings').update({
      'location_address': settings.locationAddress.trim(),
      'location_maps_url': _clean(settings.locationMapsUrl),
      'booking_horizon_days': settings.bookingHorizonDays,
      'pending_hold_hours': settings.pendingHoldHours,
      'lesson_duration_label': settings.lessonDurationLabel.trim(),
    }).eq('id', 1);
  }

  Future<void> createAppointment({
    required String studentId,
    required DateTime startsAt,
    required int minutes,
    String? note,
  }) async {
    await _client.rpc('admin_create_appointment', params: {
      'p_student_id': studentId,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_minutes': minutes,
      'p_note': _clean(note),
    });
  }

  Future<void> updateAppointment({
    required String id,
    required DateTime newStartsAt,
    String? reason,
  }) async {
    await _client.rpc('admin_update_appointment', params: {
      'p_id': id,
      'p_new_starts_at': newStartsAt.toUtc().toIso8601String(),
      'p_reason': _clean(reason),
    });
  }

  Future<void> cancelAppointment({required String id, String? reason}) async {
    await _client.rpc('admin_cancel_appointment', params: {
      'p_id': id,
      'p_reason': _clean(reason),
    });
  }

  Future<void> setAttendance({
    required String id,
    required String outcome,
  }) async {
    await _client.rpc('admin_set_attendance', params: {
      'p_id': id,
      'p_outcome': outcome,
    });
  }

  AdminAppointment _appointmentFromRow(dynamic value) {
    final row = Map<String, dynamic>.from(value as Map);
    final student = _map(row['student']);
    final university = _map(student['university']);
    return AdminAppointment(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      studentName: student['full_name'] as String? ?? 'طالب',
      studentPhone: student['phone'] as String?,
      universityName: university['name'] as String?,
      studyYear: student['study_year'] as String?,
      isGraduating: student['is_graduating'] as bool? ?? false,
      startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(row['ends_at'] as String).toLocal(),
      status: row['status'] as String,
      studentNote: row['student_note'] as String?,
      adminNote: row['admin_note'] as String?,
      isExceptional: row['is_exceptional'] as bool? ?? false,
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  String _time(dynamic value) => (value as String).substring(0, 5);

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String? _clean(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
