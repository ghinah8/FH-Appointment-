import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/admin_dashboard_data.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/appointments_admin_cubit.dart';
import 'admin_management_pages.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => sl<AppointmentsAdminCubit>()..loadPendingAppointments(),
          ),
          BlocProvider(
            create: (_) => sl<AdminDashboardCubit>()..load(),
          ),
        ],
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const _Brand(light: true),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'تحديث البيانات',
                    onPressed: () {
                      context.read<AppointmentsAdminCubit>().loadPendingAppointments();
                      context.read<AdminDashboardCubit>().load();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.cream,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(icon: Icon(Icons.inbox_outlined), text: 'الطلبات'),
                  Tab(icon: Icon(Icons.calendar_month_outlined), text: 'التقويم'),
                  Tab(icon: Icon(Icons.schedule_outlined), text: 'الدوام'),
                  Tab(icon: Icon(Icons.people_outline), text: 'الطلاب'),
                  Tab(icon: Icon(Icons.settings_outlined), text: 'الإعدادات'),
                ],
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: TabBarView(
                    children: [
                      _AdminRequestsTab(adminName: user.fullName),
                      AdminCalendarTab(user: user),
                      const AdminAvailabilityTab(),
                      const AdminStudentsTab(),
                      const AdminSettingsTab(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AdminRequestsTab extends StatelessWidget {
  const _AdminRequestsTab({required this.adminName});
  final String adminName;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('أهلاً، $adminName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 20),
          const Text('طلبات الحجز الجديدة', style: _sectionTitle),
          const SizedBox(height: 12),
          BlocConsumer<AppointmentsAdminCubit, AppointmentsAdminState>(
            listenWhen: (previous, current) =>
                current is AppointmentsAdminError,
            listener: (context, state) {
              if (state is AppointmentsAdminError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final appointments = switch (state) {
                AppointmentsAdminLoaded(:final appointments) => appointments,
                AppointmentsAdminLoading(:final appointments) => appointments,
                AppointmentsAdminActionLoading(:final appointments) => appointments,
                AppointmentsAdminError(:final appointments) => appointments,
                _ => <AdminAppointment>[],
              };
              if (appointments.isEmpty && state is AppointmentsAdminLoading) {
                return const _EmptyPanel(
                  icon: Icons.hourglass_top_rounded,
                  title: 'جاري تحميل الطلبات',
                  subtitle: 'يرجى الانتظار قليلاً',
                  action: Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                );
              }
              if (state is AppointmentsAdminError && appointments.isEmpty) {
                return _EmptyPanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'تعذر تحميل طلبات الحجز',
                  subtitle: state.message,
                  action: FilledButton.icon(
                    onPressed: context.read<AppointmentsAdminCubit>().loadPendingAppointments,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                );
              }
              if (appointments.isEmpty) {
                return const _EmptyPanel(
                  icon: Icons.inbox_outlined,
                  title: 'لا توجد طلبات حجز معلقة',
                  subtitle: 'ستظهر الطلبات الجديدة هنا.',
                );
              }
              final busyId = state is AppointmentsAdminActionLoading ? state.appointmentId : null;
              return Column(
                children: appointments.map((appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AdminAppointmentCard(
                    appointment: appointment,
                    isLoading: busyId == appointment.id,
                    anyActionLoading: state is AppointmentsAdminActionLoading,
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text('طلبات تعديل وإلغاء المواعيد', style: _sectionTitle),
          const SizedBox(height: 12),
          const AdminChangeRequestsSection(),
        ],
      );
}

const _sectionTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary);

class AdminChangeRequestsSection extends StatelessWidget {
  const AdminChangeRequestsSection({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.changeRequests.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
          }
          if (state.error != null && state.changeRequests.isEmpty) {
            return _EmptyPanel(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل طلبات التعديل',
              subtitle: state.error!,
            );
          }
          if (state.changeRequests.isEmpty) {
            return const _EmptyPanel(
              icon: Icons.inbox_outlined,
              title: 'لا توجد طلبات تعديل أو إلغاء',
              subtitle: 'طلبات الطلاب ستظهر هنا.',
            );
          }
          return Column(children: state.changeRequests.map((request) => _ChangeRequestCard(request: request)).toList());
        },
      );
}

class _ChangeRequestCard extends StatelessWidget {
  const _ChangeRequestCard({required this.request});
  final AdminChangeRequest request;

  @override
  Widget build(BuildContext context) {
    final isReschedule = request.type == 'reschedule';
    final busy = context.watch<AdminDashboardCubit>().state.isBusy;
    final dateFormat = DateFormat('yyyy/MM/dd  h:mm a', 'en');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(isReschedule ? 'طلب تعديل موعد' : 'طلب إلغاء موعد'),
          Text('الموعد الحالي: ${dateFormat.format(request.currentStartsAt)}'),
          if (request.requestedStartsAt != null) Text('الموعد المقترح: ${dateFormat.format(request.requestedStartsAt!)}'),
          if (request.reason?.trim().isNotEmpty == true) Text('السبب: ${request.reason}'),
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            FilledButton.icon(
              onPressed: busy ? null : () => context.read<AdminDashboardCubit>().decideChangeRequest(
                request: request, approve: true, newStartsAt: request.requestedStartsAt,
              ),
              icon: const Icon(Icons.check_rounded), label: const Text('موافقة'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => context.read<AdminDashboardCubit>().decideChangeRequest(
                request: request, approve: false,
              ),
              icon: const Icon(Icons.close_rounded), label: const Text('رفض'),
            ),
          ]),
        ]),
      ),
    );
  }
}
class _AdminAppointmentCard extends StatelessWidget {
  const _AdminAppointmentCard({
    required this.appointment,
    required this.isLoading,
    required this.anyActionLoading,
  });

  final AdminAppointment appointment;
  final bool isLoading;
  final bool anyActionLoading;

  Future<void> _handleDecision(
    BuildContext context, {
    required bool confirm,
  }) async {
    final noteController = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirm ? 'قبول طلب الحجز' : 'رفض طلب الحجز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirm ? 'هل تريد تأكيد هذا الموعد؟' : 'هل تريد رفض هذا الطلب؟',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختيارية)',
                hintText: 'يمكنك إضافة ملاحظة للطالب',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: confirm
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
            onPressed: () {
              Navigator.of(dialogContext).pop(noteController.text);
            },
            child: Text(confirm ? 'تأكيد القبول' : 'تأكيد الرفض'),
          ),
        ],
      ),
    );

    noteController.dispose();

    if (note == null || !context.mounted) return;

    final success = await context.read<AppointmentsAdminCubit>().decide(
          appointment: appointment,
          confirm: confirm,
          note: note,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? confirm
                  ? 'تم قبول طلب الحجز.'
                  : 'تم رفض طلب الحجز.'
              : 'لم يتم تحديث الطلب. تحققي من رسالة الخطأ وحاولي مجدداً.',
        ),
        backgroundColor: success ? AppColors.primary : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy/MM/dd').format(appointment.startsAt);
    final startTime = DateFormat('h:mm a', 'en').format(appointment.startsAt);
    final endTime = DateFormat('h:mm a', 'en').format(appointment.endsAt);

    final studyYear = appointment.studyYear;
    final yearLabel = studyYear == null || studyYear.isEmpty
        ? 'غير محدد'
        : studyYear == 'fourth'
            ? 'السنة الرابعة'
            : studyYear == 'fifth'
                ? 'السنة الخامسة'
                : studyYear == 'fifthGraduating'
                    ? 'السنة الخامسة - سنة تخرج'
                    : studyYear;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.studentName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      appointment.universityName ?? 'الجامعة غير محددة',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.isExceptional)
                const Chip(
                  avatar: Icon(Icons.star_outline_rounded, size: 17),
                  label: Text('موعد استثنائي'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          _AdminDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ',
            value: date,
          ),
          const SizedBox(height: 10),
          _AdminDetailRow(
            icon: Icons.schedule_rounded,
            label: 'الوقت',
            value: '$startTime - $endTime',
          ),
          const SizedBox(height: 10),
          _AdminDetailRow(
            icon: Icons.school_outlined,
            label: 'السنة الدراسية',
            value: appointment.isGraduating && studyYear == 'fifth'
                ? 'السنة الخامسة - سنة تخرج'
                : yearLabel,
          ),
          if (appointment.studentPhone?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _AdminDetailRow(
              icon: Icons.phone_outlined,
              label: 'رقم الهاتف',
              value: appointment.studentPhone!,
            ),
          ],
          if (appointment.studentNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _AdminNoteBox(
              title: 'ملاحظة الطالب',
              note: appointment.studentNote!,
            ),
          ],
          if (appointment.adminNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _AdminNoteBox(
              title: 'ملاحظة الإدارة السابقة',
              note: appointment.adminNote!,
            ),
          ],
          const SizedBox(height: 20),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;

                final rejectButton = OutlinedButton.icon(
                  onPressed: anyActionLoading
                      ? null
                      : () => _handleDecision(context, confirm: false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض الطلب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                );

                final acceptButton = FilledButton.icon(
                  onPressed: anyActionLoading
                      ? null
                      : () => _handleDecision(context, confirm: true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('قبول الطلب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      acceptButton,
                      const SizedBox(height: 10),
                      rejectButton,
                    ],
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    acceptButton,
                    rejectButton,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdminDetailRow extends StatelessWidget {
  const _AdminDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.forest),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminNoteBox extends StatelessWidget {
  const _AdminNoteBox({
    required this.title,
    required this.note,
  });

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, size: 34, color: AppColors.sage),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted)),
        if (action != null) ...[const SizedBox(height: 12), action!]
      ]));
}

class _Brand extends StatelessWidget {
  const _Brand({this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: light ? Colors.white.withValues(alpha: .12) : AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('FH', style: TextStyle(color: light ? Colors.white : AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text('FATIMA HABIB', style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: light ? Colors.white : AppColors.primary)),
        ],
      );
}
