import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/available_slot.dart';

class BookingRemoteDataSource {
  BookingRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AvailableSlot>> getAvailableSlots() async {
    final rows = await _client.rpc('get_available_slots') as List<dynamic>;

    return rows.map((row) {
      final json = Map<String, dynamic>.from(row as Map);

      return AvailableSlot(
        startsAt: DateTime.parse(json['slot_start'] as String).toLocal(),
        endsAt: DateTime.parse(json['slot_end'] as String).toLocal(),
      );
    }).toList();
  }

  Future<void> requestAppointment(DateTime startsAt) async {
    await _client.rpc(
      'create_appointment',
      params: {
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_note': null,
      },
    );
  }

  Future<List<Appointment>> getMyAppointments() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('not_authenticated');
    }

    final rows = await _client
        .from('appointments')
        .select(
          'id, starts_at, ends_at, status, student_note, '
          'admin_note, is_exceptional, expires_at',
        )
        .eq('student_id', user.id)
        .order('starts_at', ascending: false);

    return (rows as List<dynamic>).map((row) {
      final json = Map<String, dynamic>.from(row as Map);

      return Appointment(
        id: json['id'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        status: json['status'] as String,
        studentNote: json['student_note'] as String?,
        adminNote: json['admin_note'] as String?,
        isExceptional: json['is_exceptional'] as bool? ?? false,
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    }).toList();
  }

  Future<List<AdminAppointment>> getPendingAppointments() async {
    final rows = await _client
        .from('appointments')
        .select(
          'id, student_id, starts_at, ends_at, status, '
          'student_note, admin_note, is_exceptional, expires_at, '
          'student:profiles!appointments_student_id_fkey('
          'full_name, phone, study_year, is_graduating, '
          'university:universities(name)'
          ')',
        )
        .eq('status', 'pending')
        .order('starts_at', ascending: true);

    return (rows as List<dynamic>).map((row) {
      final json = Map<String, dynamic>.from(row as Map);

      final studentValue = json['student'];
      final student = studentValue is Map
          ? Map<String, dynamic>.from(studentValue)
          : <String, dynamic>{};

      final universityValue = student['university'];
      final university = universityValue is Map
          ? Map<String, dynamic>.from(universityValue)
          : <String, dynamic>{};

      return AdminAppointment(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        studentName: student['full_name'] as String? ?? 'طالب بدون اسم',
        studentPhone: student['phone'] as String?,
        universityName: university['name'] as String?,
        studyYear: student['study_year'] as String?,
        isGraduating: student['is_graduating'] as bool? ?? false,
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        status: json['status'] as String,
        studentNote: json['student_note'] as String?,
        adminNote: json['admin_note'] as String?,
        isExceptional: json['is_exceptional'] as bool? ?? false,
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    }).toList();
  }

  Future<void> decideAppointment({
    required String appointmentId,
    required bool confirm,
    String? note,
  }) async {
    await _client.rpc(
      'admin_decide_appointment',
      params: {
        'p_id': appointmentId,
        'p_confirm': confirm,
        'p_note': note,
      },
    );
  }
}
