// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_appointment.dart';
import '../cubit/appointments_admin_cubit.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/booking_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import 'my_appointments_page.dart';

/// نقطة الدخول بعد المصادقة: تعرض واجهة الطالب أو لوحة الإدارة حسب الدور.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user.isAdmin) return _AdminHome(user: user);
    return BlocProvider(
      create: (_) => sl<BookingCubit>()..loadSlots(),
      child: _StudentHome(user: user),
    );
  }
}

class _StudentHome extends StatelessWidget {
  const _StudentHome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const _Brand(),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyAppointmentsPage(
                    cubit: sl<AppointmentsCubit>(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.event_note_rounded),
            label: const Text('مواعيدي'),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.forest,
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'FH  •  FATIMA HABIB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'أهلاً وسهلاً، ${user.fullName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'احجز موعدك، ونظّم وقتك، وتابع طلبات الحجز بسهولة.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 19,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'مكان الدرس: فرقان، دوار الصخرة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Section heading
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.forest,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المواعيد المتاحة',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'اختر اليوم والوقت المناسبين.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث المواعيد',
                      onPressed: () {
                        context.read<BookingCubit>().loadSlots();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                BlocConsumer<BookingCubit, BookingState>(
                  listenWhen: (previous, current) =>
                      previous.message != current.message &&
                      current.message != null,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message!),
                        backgroundColor:
                            state.isError ? AppColors.error : AppColors.primary,
                      ),
                    );
                  },
                  builder: (context, state) {
                    // Loading
                    if (state.isLoading && state.slots.isEmpty) {
                      return _studentPanel(
                        icon: Icons.hourglass_top_rounded,
                        title: 'جارٍ تحميل المواعيد',
                        subtitle: 'يرجى الانتظار قليلاً...',
                        child: const Padding(
                          padding: EdgeInsets.only(top: 22),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Error
                    if (state.isError && state.slots.isEmpty) {
                      return _studentPanel(
                        icon: Icons.cloud_off_rounded,
                        title: 'تعذّر تحميل المواعيد',
                        subtitle: state.message ??
                            'حدث خطأ أثناء الاتصال. يرجى المحاولة مجدداً.',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: FilledButton.icon(
                            onPressed: () {
                              context.read<BookingCubit>().loadSlots();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ),
                      );
                    }

                    // No appointments
                    if (state.slots.isEmpty) {
                      return _studentPanel(
                        icon: Icons.event_busy_rounded,
                        title: 'لا توجد مواعيد متاحة حالياً',
                        subtitle:
                            'ستظهر المواعيد هنا عند توفرها. يمكنك تحديث القائمة لاحقاً.',
                      );
                    }

                    // Group actual slots by their local date.
                    final groups = <String, List<dynamic>>{};

                    for (final slot in state.slots) {
                      final key =
                          DateFormat('yyyy-MM-dd').format(slot.startsAt);

                      groups.putIfAbsent(key, () => []).add(slot);
                    }

                    final dates = groups.keys.toList()..sort();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isLoading) const LinearProgressIndicator(),
                        if (state.isError)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.message ?? 'تعذّر تحديث المواعيد.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ...dates.map((dateKey) {
                          final daySlots = groups[dateKey]!
                            ..sort(
                              (a, b) => a.startsAt.compareTo(b.startsAt),
                            );

                          final day = daySlots.first.startsAt;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.cream,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _arabicDate(day),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${daySlots.length} موعد متاح',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 680
                                        ? 3
                                        : constraints.maxWidth >= 420
                                            ? 2
                                            : 1;

                                    const spacing = 12.0;

                                    final itemWidth = (constraints.maxWidth -
                                            (columns - 1) * spacing) /
                                        columns;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: daySlots.map<Widget>((slot) {
                                        final startsAt = slot.startsAt;
                                        final busy =
                                            state.requestingSlot == startsAt;

                                        return SizedBox(
                                          width: itemWidth,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFAFAF7),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.schedule_rounded,
                                                  color: AppColors.forest,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 9),
                                                Text(
                                                  DateFormat('h:mm a', 'en')
                                                      .format(startsAt),
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: FilledButton(
                                                    onPressed:
                                                        state.requestingSlot !=
                                                                    null ||
                                                                state.isLoading
                                                            ? null
                                                            : () async {
                                                                final ok =
                                                                    await showDialog<
                                                                        bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (dialogContext) =>
                                                                          AlertDialog(
                                                                    title:
                                                                        const Text(
                                                                      'تأكيد طلب الحجز',
                                                                    ),
                                                                    content:
                                                                        Text(
                                                                      'هل تريد تأكيد طلب الحجز ليوم ${_arabicDate(startsAt)} الساعة ${DateFormat('h:mm a', 'en').format(startsAt)}؟ سيبقى الطلب بانتظار موافقة الآنسة فاطمة.',
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () => Navigator.pop(
                                                                            dialogContext,
                                                                            false),
                                                                        child:
                                                                            const Text(
                                                                          'إلغاء',
                                                                        ),
                                                                      ),
                                                                      FilledButton(
                                                                        onPressed: () => Navigator.pop(
                                                                            dialogContext,
                                                                            true),
                                                                        child:
                                                                            const Text(
                                                                          'تأكيد الحجز',
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );

                                                                if (ok ==
                                                                        true &&
                                                                    context
                                                                        .mounted) {
                                                                  await context
                                                                      .read<
                                                                          BookingCubit>()
                                                                      .book(
                                                                          slot);
                                                                }
                                                              },
                                                    child: busy
                                                        ? const SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : const Text(
                                                            'اختيار الموعد',
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Booking information
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.forest,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معلومات الحجز',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'مدة الدرس من 30 إلى 45 دقيقة. إرسال الطلب لا يعني تأكيد الحجز؛ يجب انتظار موافقة الإدارة.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _studentPanel({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 30,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.8,
              color: AppColors.muted,
            ),
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  static String _arabicDate(DateTime date) {
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

    return '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]}';
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentsAdminCubit>()..loadPendingAppointments(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F5),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const _Brand(light: true),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => context.read<AuthCubit>().signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'أهلاً، ${user.fullName}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'لوحة إدارة الحجوزات',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),

                  // ملخص أقسام لوحة الإدارة
                  const Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _AdminTile(
                        icon: Icons.inbox_outlined,
                        title: 'طلبات الحجز',
                        subtitle: 'مراجعة الطلبات المعلّقة',
                      ),
                      _AdminTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'التقويم',
                        subtitle: 'عرض وإدارة المواعيد',
                      ),
                      _AdminTile(
                        icon: Icons.schedule_outlined,
                        title: 'إعدادات الدوام',
                        subtitle: 'أيام الدوام والاستثناءات',
                      ),
                      _AdminTile(
                        icon: Icons.people_outline,
                        title: 'الطلاب',
                        subtitle: 'بيانات الطلاب وسجل الحجوزات',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'طلبات الحجز المعلّقة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'تحديث الطلبات',
                        onPressed: () {
                          context
                              .read<AppointmentsAdminCubit>()
                              .loadPendingAppointments();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

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
                      if (state is AppointmentsAdminInitial ||
                          state is AppointmentsAdminLoading) {
                        return const _EmptyPanel(
                          icon: Icons.hourglass_top_rounded,
                          title: 'جارٍ تحميل الطلبات',
                          subtitle: 'يرجى الانتظار قليلاً...',
                          action: Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (state is AppointmentsAdminError) {
                        return _EmptyPanel(
                          icon: Icons.cloud_off_outlined,
                          title: 'تعذّر تحميل طلبات الحجز',
                          subtitle: state.message,
                          action: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FilledButton.icon(
                              onPressed: () {
                                context
                                    .read<AppointmentsAdminCubit>()
                                    .loadPendingAppointments();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ),
                        );
                      }

                      final appointments = state is AppointmentsAdminLoaded
                          ? state.appointments
                          : state is AppointmentsAdminActionLoading
                              ? state.appointments
                              : <AdminAppointment>[];

                      if (appointments.isEmpty) {
                        return const _EmptyPanel(
                          icon: Icons.inbox_outlined,
                          title: 'لا توجد طلبات معلّقة',
                          subtitle:
                              'ستظهر هنا طلبات الحجز الجديدة عند إرسالها من الطلاب.',
                        );
                      }

                      final actionLoadingId =
                          state is AppointmentsAdminActionLoading
                              ? state.appointmentId
                              : null;

                      return Column(
                        children: appointments.map((appointment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _AdminAppointmentCard(
                              appointment: appointment,
                              isLoading: actionLoadingId == appointment.id,
                              anyActionLoading:
                                  state is AppointmentsAdminActionLoading,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _AdminTile extends StatelessWidget {
  const _AdminTile(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 250,
      child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border)),
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.forest, size: 28),
                    const SizedBox(height: 14),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.muted))
                  ]))));
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

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14)),
      child: const Row(children: [
        Icon(Icons.location_on_outlined, color: AppColors.forest),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مكان الدرس', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text('فرقان، دوار الصخرة', style: TextStyle(color: AppColors.muted))
        ]))
      ]));
}

class _Brand extends StatelessWidget {
  const _Brand({this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: light
                    ? Colors.white.withValues(alpha: .12)
                    : AppColors.cream,
                borderRadius: BorderRadius.circular(10)),
            child: Text('FH',
                style: TextStyle(
                    color: light ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Text('FATIMA HABIB',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: light ? Colors.white : AppColors.primary))
      ]);
}
