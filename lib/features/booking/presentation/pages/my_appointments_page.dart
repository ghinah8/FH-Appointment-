import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/appointment.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';

class MyAppointmentsPage extends StatelessWidget {
  const MyAppointmentsPage({
    super.key,
    required this.cubit,
  });

  final AppointmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit..loadAppointments(),
      child: const _MyAppointmentsView(),
    );
  }
}

class _MyAppointmentsView extends StatelessWidget {
  const _MyAppointmentsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: const Text(
            'مواعيدي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<AppointmentsCubit, AppointmentsState>(
          builder: (context, state) {
            if (state.isLoading && state.appointments.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.isError && state.appointments.isEmpty) {
              return _ErrorView(
                message: state.message ?? 'تعذّر تحميل المواعيد.',
                onRetry: () {
                  context.read<AppointmentsCubit>().loadAppointments();
                },
              );
            }

            final cubit = context.read<AppointmentsCubit>();
            final upcoming = cubit.upcomingAppointments;
            final past = cubit.pastAppointments;

            return RefreshIndicator(
              onRefresh: cubit.loadAppointments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.isError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        state.message ?? 'تعذّر تحديث المواعيد.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _SectionHeader(
                    title: 'المواعيد القادمة',
                    count: upcoming.length,
                  ),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    const _EmptyView(
                      message: 'ما عندك مواعيد قادمة حالياً.',
                    )
                  else
                    ...upcoming.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'المواعيد السابقة',
                    count: past.length,
                  ),
                  const SizedBox(height: 12),
                  if (past.isEmpty)
                    const _EmptyView(
                      message: 'ما عندك مواعيد سابقة.',
                    )
                  else
                    ...past.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                      ),
                    ),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAFE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5147B8),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
  });

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF5147B8),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(appointment.startsAt),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.access_time_rounded,
            text:
                '${_formatTime(appointment.startsAt)} - ${_formatTime(appointment.endsAt)}',
          ),
          if (appointment.isExceptional) ...[
            const SizedBox(height: 8),
            const _InfoRow(
              icon: Icons.star_outline_rounded,
              text: 'موعد استثنائي',
            ),
          ],
          if (appointment.studentNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظتك',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(appointment.studentNote!),
          ],
          if (appointment.adminNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظة الآنسة فاطمة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.adminNote!,
              style: const TextStyle(color: Color(0xFF55576A)),
            ),
          ],
          if (appointment.status == 'pending' &&
              appointment.expiresAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'ينتهي حجز الموعد المؤقت في ${_formatDate(appointment.expiresAt!)}، ${_formatTime(appointment.expiresAt!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF946200),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF77798C),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF55576A),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EAF1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_rounded,
            size: 36,
            color: Color(0xFF9698AA),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77798C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_StatusInfo _statusInfo(String status) {
  switch (status) {
    case 'pending':
      return const _StatusInfo('بانتظار الموافقة', Color(0xFFB7791F));
    case 'confirmed':
      return const _StatusInfo('مؤكد', Color(0xFF16805D));
    case 'rejected':
      return const _StatusInfo('مرفوض', Color(0xFFC53030));
    case 'cancellation_requested':
      return const _StatusInfo(
        'طلب إلغاء قيد المراجعة',
        Color(0xFF805AD5),
      );
    case 'reschedule_requested':
      return const _StatusInfo(
        'طلب تعديل قيد المراجعة',
        Color(0xFF805AD5),
      );
    case 'cancelled':
      return const _StatusInfo('ملغي', Color(0xFF718096));
    case 'completed':
      return const _StatusInfo('مكتمل', Color(0xFF16805D));
    case 'no_show':
      return const _StatusInfo('لم يتم الحضور', Color(0xFFC53030));
    case 'expired':
      return const _StatusInfo('انتهت المهلة', Color(0xFF718096));
    default:
      return const _StatusInfo('غير معروف', Color(0xFF718096));
  }
}

String _formatDate(DateTime date) {
  const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  const months = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'ص' : 'م';

  return '$hour:$minute $period';
}
