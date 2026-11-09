import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/public_app_settings_cubit.dart';
import 'my_appointments_page.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key, required this.user});

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
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 19,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: BlocBuilder<PublicAppSettingsCubit,
                                PublicAppSettingsState>(
                              builder: (context, state) {
                                final address = state is PublicAppSettingsLoaded
                                    ? state.settings.locationAddress
                                    : state is PublicAppSettingsError
                                        ? 'تعذر تحميل معلومات الموقع'
                                        : 'تُحمّل معلومات الموقع';
                                return Text(
                                  'مكان الدرس: $address',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                );
                              },
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

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'FH',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FATIMA HABIB',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      );
}
