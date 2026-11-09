import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/entities/admin_dashboard_data.dart';
import '../cubit/admin_dashboard_cubit.dart';

class AdminCalendarTab extends StatefulWidget {
  const AdminCalendarTab({super.key, required this.user});

  final AppUser user;

  @override
  State<AdminCalendarTab> createState() => _AdminCalendarTabState();
}

class _AdminCalendarTabState extends State<AdminCalendarTab> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          final appointments = state.appointments
              .where(
                  (item) => DateUtils.isSameDay(item.startsAt, _selectedDate))
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TabHeading(
                title: 'التقويم والمواعيد',
                subtitle: 'مرحباً ${widget.user.fullName}، أدِر مواعيد الطلاب.',
                trailing: Wrap(spacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateUtils.dateOnly(DateTime.now()),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
                  ),
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: context.read<AdminDashboardCubit>(),
                                child: CreateAppointmentDialog(
                                  initialDate: _selectedDate,
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.add),
                    label: const Text('موعد استثنائي'),
                  ),
                ]),
              ),
              if (state.error != null) _ErrorBanner(message: state.error!),
              if (state.conflicts.isNotEmpty)
                _ConflictPanel(conflicts: state.conflicts),
              if (state.isLoading && state.appointments.isEmpty)
                const _LoadingPanel()
              else if (appointments.isEmpty)
                const _EmptyPanel(
                  icon: Icons.event_available_outlined,
                  title: 'لا توجد مواعيد في هذا اليوم',
                  subtitle: 'اختر يوماً آخر أو أضف موعداً استثنائياً.',
                )
              else
                ...appointments.map((appointment) => _ScheduleAppointmentCard(
                      appointment: appointment,
                      busy: state.isBusy,
                    )),
            ],
          );
        },
      );
}

class _ScheduleAppointmentCard extends StatelessWidget {
  const _ScheduleAppointmentCard(
      {required this.appointment, required this.busy});

  final AdminAppointment appointment;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminDashboardCubit>();
    final dateTime = DateFormat('h:mm a', 'en');
    final isConfirmed = appointment.status == 'confirmed';
    final canMarkAttendance =
        isConfirmed && appointment.startsAt.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.forest),
            const SizedBox(width: 10),
            Expanded(
                child: Text(appointment.studentName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold))),
            _StatusChip(status: appointment.status),
          ]),
          const SizedBox(height: 8),
          Text(
              '${dateTime.format(appointment.startsAt)} – ${dateTime.format(appointment.endsAt)}'),
          if (appointment.studentPhone?.isNotEmpty == true)
            Text('الهاتف: ${appointment.studentPhone}'),
          if (appointment.isExceptional) const Text('موعد أنشأته الإدارة'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: busy ||
                      ![
                        'pending',
                        'confirmed',
                        'cancellation_requested',
                        'reschedule_requested'
                      ].contains(appointment.status)
                  ? null
                  : () => _reschedule(context),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('تغيير الوقت'),
            ),
            OutlinedButton.icon(
              onPressed: busy ||
                      ![
                        'pending',
                        'confirmed',
                        'cancellation_requested',
                        'reschedule_requested'
                      ].contains(appointment.status)
                  ? null
                  : () => _cancel(context),
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('إلغاء الموعد'),
            ),
            if (canMarkAttendance) ...[
              FilledButton.tonalIcon(
                onPressed:
                    busy ? null : () => _attendance(context, 'completed'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('حضر'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _attendance(context, 'no_show'),
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('لم يحضر'),
              ),
            ],
          ]),
          if (appointment.studentNote?.trim().isNotEmpty == true)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('ملاحظة الطالب: ${appointment.studentNote}')),
        ]),
      ),
    );
  }

  Future<void> _reschedule(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appointment.startsAt.isBefore(DateTime.now())
          ? DateTime.now()
          : appointment.startsAt,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.startsAt));
    if (time == null || !context.mounted) return;
    final next =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final ok = await context.read<AdminDashboardCubit>().updateAppointment(
          id: appointment.id,
          newStartsAt: next,
        );
    if (context.mounted) _showResult(context, ok);
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await _reasonDialog(context, title: 'تأكيد إلغاء الموعد');
    if (reason == null || !context.mounted) return;
    final ok = await context
        .read<AdminDashboardCubit>()
        .cancelAppointment(id: appointment.id, reason: reason);
    if (context.mounted) _showResult(context, ok);
  }

  Future<void> _attendance(BuildContext context, String outcome) async {
    final ok = await context
        .read<AdminDashboardCubit>()
        .setAttendance(id: appointment.id, outcome: outcome);
    if (context.mounted) _showResult(context, ok);
  }
}

class _ConflictPanel extends StatelessWidget {
  const _ConflictPanel({required this.conflicts});
  final List<AdminAppointment> conflicts;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pendingBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pendingFg.withValues(alpha: .3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مواعيد خارج الدوام أو ضمن إغلاق',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.pendingFg)),
          const SizedBox(height: 8),
          ...conflicts.map((item) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                    '${item.studentName} · ${DateFormat('yyyy/MM/dd h:mm a', 'en').format(item.startsAt)}'),
              )),
        ]),
      );
}

class CreateAppointmentDialog extends StatefulWidget {
  const CreateAppointmentDialog({super.key, this.initialDate, this.student});

  final DateTime? initialDate;
  final AdminStudent? student;

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 11, minute: 0);
  String? _studentId;
  int _minutes = 60;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateUtils.dateOnly(DateTime.now());
    _studentId = widget.student?.id;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة موعد استثنائي'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.student == null)
                  BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
                    builder: (context, state) =>
                        DropdownButtonFormField<String>(
                      initialValue: _studentId,
                      decoration: const InputDecoration(labelText: 'الطالب'),
                      items: state.students
                          .map((student) => DropdownMenuItem(
                                value: student.id,
                                child: Text(student.fullName,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _studentId = value),
                      validator: (value) =>
                          value == null ? 'اختر الطالب' : null,
                    ),
                  )
                else
                  Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(widget.student!.fullName)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateUtils.dateOnly(DateTime.now()),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (value != null) setState(() => _date = value);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat('yyyy/MM/dd').format(_date)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showTimePicker(
                          context: context, initialTime: _time);
                      if (value != null) setState(() => _time = value);
                    },
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_time.format(context)),
                  )),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _minutes,
                  decoration: const InputDecoration(labelText: 'مدة الموعد'),
                  items: const [30, 45, 60, 90, 120]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('$value دقيقة')))
                      .toList(),
                  onChanged: (value) => setState(() => _minutes = value ?? 60),
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _note,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'ملاحظة (اختيارية)')),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final studentId = widget.student?.id ?? _studentId;
              if (studentId == null) return;
              final start = DateTime(
                  _date.year, _date.month, _date.day, _time.hour, _time.minute);
              final ok =
                  await context.read<AdminDashboardCubit>().createAppointment(
                        studentId: studentId,
                        startsAt: start,
                        minutes: _minutes,
                        note: _note.text,
                      );
              if (context.mounted && ok) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إنشاء الموعد الاستثنائي')),
                );
              }
              if (context.mounted && !ok) _showResult(context, false);
            },
            child: const Text('حفظ الموعد'),
          ),
        ],
      );
}

class AdminAvailabilityTab extends StatelessWidget {
  const AdminAvailabilityTab({super.key});

  static const _weekdays = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TabHeading(
              title: 'إعدادات الدوام',
              subtitle: 'حدّد الدوام الأسبوعي والاستثناءات والعطل.',
              trailing: Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                    onPressed: () => _editException(context),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('استثناء')),
                FilledButton.icon(
                    onPressed: () => _editRule(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة دوام')),
              ]),
            ),
            if (state.error != null) _ErrorBanner(message: state.error!),
            const Text('الدوام الأسبوعي', style: _pageTitle),
            if (state.isLoading && state.rules.isEmpty)
              const _LoadingPanel()
            else if (state.rules.isEmpty)
              const _EmptyPanel(
                  icon: Icons.schedule_outlined,
                  title: 'لا توجد ساعات دوام',
                  subtitle: 'أضف ساعات الدوام الأسبوعية للبدء.')
            else
              ...state.rules.map((rule) => Card(
                    child: ListTile(
                      leading: Icon(
                          rule.isActive
                              ? Icons.schedule
                              : Icons.pause_circle_outline,
                          color: AppColors.forest),
                      title: Text(
                          '${_weekdays[rule.weekday]}  ${rule.startTime} – ${rule.endTime}'),
                      subtitle: Text(
                          'مدة الفتحة ${rule.slotMinutes} دقيقة · ${rule.isActive ? 'مفعّل' : 'متوقف'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _editRule(context, rule: rule),
                            icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _delete(context, rule.id, true),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error)),
                      ]),
                    ),
                  )),
            const SizedBox(height: 24),
            const Text('الاستثناءات والعطل', style: _pageTitle),
            if (state.exceptions.isEmpty)
              const _EmptyPanel(
                  icon: Icons.event_busy_outlined,
                  title: 'لا توجد استثناءات',
                  subtitle: 'أضف إغلاقاً أو ساعات إضافية لتاريخ محدد.')
            else
              ...state.exceptions.map((item) => Card(
                    child: ListTile(
                      leading: Icon(
                          item.type == 'closure'
                              ? Icons.block
                              : Icons.more_time,
                          color: item.type == 'closure'
                              ? AppColors.error
                              : AppColors.forest),
                      title: Text(
                          '${DateFormat('yyyy/MM/dd').format(item.date)} · ${item.type == 'closure' ? 'إغلاق' : 'ساعات إضافية'}'),
                      subtitle: Text([
                        if (item.startTime != null)
                          '${item.startTime} – ${item.endTime}',
                        if (item.reason?.isNotEmpty == true) item.reason!
                      ].join(' · ')),
                      trailing: IconButton(
                          tooltip: 'حذف',
                          onPressed: () => _delete(context, item.id, false),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error)),
                    ),
                  )),
          ],
        ),
      );

  Future<void> _editRule(BuildContext context, {AvailabilityRule? rule}) async {
    final value = await showDialog<_RuleFormValue>(
        context: context, builder: (_) => _RuleDialog(rule: rule));
    if (value == null || !context.mounted) return;
    final ok = await context.read<AdminDashboardCubit>().saveRule(
          id: rule?.id,
          weekday: value.weekday,
          startTime: _timeString(value.start),
          endTime: _timeString(value.end),
          slotMinutes: value.minutes,
          isActive: value.active,
        );
    if (context.mounted) _showResult(context, ok);
  }

  Future<void> _editException(BuildContext context) async {
    final value = await showDialog<_ExceptionFormValue>(
        context: context, builder: (_) => const _ExceptionDialog());
    if (value == null || !context.mounted) return;
    final ok = await context.read<AdminDashboardCubit>().saveException(
          date: value.date,
          type: value.type,
          startTime: value.allDay ? null : _timeString(value.start),
          endTime: value.allDay ? null : _timeString(value.end),
          reason: value.reason,
        );
    if (context.mounted) _showResult(context, ok);
  }

  Future<void> _delete(BuildContext context, String id, bool rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(rule
            ? 'سيُحذف نطاق الدوام المحدد.'
            : 'سيُحذف استثناء الدوام المحدد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = rule
        ? await context.read<AdminDashboardCubit>().deleteRule(id)
        : await context.read<AdminDashboardCubit>().deleteException(id);
    if (context.mounted) _showResult(context, ok);
  }
}

class _RuleFormValue {
  const _RuleFormValue(
      this.weekday, this.start, this.end, this.minutes, this.active);
  final int weekday;
  final TimeOfDay start;
  final TimeOfDay end;
  final int minutes;
  final bool active;
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.rule});
  final AvailabilityRule? rule;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late int _weekday;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _minutes;
  late bool _active;

  TimeOfDay _parse(String? value, TimeOfDay fallback) {
    if (value == null) return fallback;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _weekday = rule?.weekday ?? 0;
    _start = _parse(rule?.startTime, const TimeOfDay(hour: 11, minute: 0));
    _end = _parse(rule?.endTime, const TimeOfDay(hour: 17, minute: 0));
    _minutes = rule?.slotMinutes ?? 60;
    _active = rule?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.rule == null ? 'إضافة دوام' : 'تعديل الدوام'),
        content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                  value: _weekday,
                  decoration: const InputDecoration(labelText: 'اليوم'),
                  items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                          value: i,
                          child: Text(AdminAvailabilityTab._weekdays[i]))),
                  onChanged: (v) => setState(() => _weekday = v ?? 0)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _TimeButton(
                        label: 'من',
                        time: _start,
                        onSelected: (v) => setState(() => _start = v))),
                const SizedBox(width: 8),
                Expanded(
                    child: _TimeButton(
                        label: 'إلى',
                        time: _end,
                        onSelected: (v) => setState(() => _end = v))),
              ]),
              DropdownButtonFormField<int>(
                  value: _minutes,
                  decoration: const InputDecoration(labelText: 'مدة الموعد'),
                  items: const [30, 45, 60, 90, 120]
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text('$m دقيقة')))
                      .toList(),
                  onChanged: (v) => setState(() => _minutes = v ?? 60)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الدوام مفعّل'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v)),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () {
                if (_end.hour * 60 + _end.minute <=
                    _start.hour * 60 + _start.minute) return;
                Navigator.pop(context,
                    _RuleFormValue(_weekday, _start, _end, _minutes, _active));
              },
              child: const Text('حفظ')),
        ],
      );
}

class _ExceptionFormValue {
  const _ExceptionFormValue(
      this.date, this.type, this.start, this.end, this.allDay, this.reason);
  final DateTime date;
  final String type;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool allDay;
  final String reason;
}

class _ExceptionDialog extends StatefulWidget {
  const _ExceptionDialog();

  @override
  State<_ExceptionDialog> createState() => _ExceptionDialogState();
}

class _ExceptionDialogState extends State<_ExceptionDialog> {
  final _reason = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String _type = 'closure';
  TimeOfDay _start = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _allDay = true;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة استثناء للدوام'),
        content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'النوع'),
                  items: const [
                    DropdownMenuItem(value: 'closure', child: Text('إغلاق')),
                    DropdownMenuItem(
                        value: 'extra_hours', child: Text('ساعات إضافية'))
                  ],
                  onChanged: (v) => setState(() {
                        _type = v ?? 'closure';
                        if (_type == 'extra_hours') _allDay = false;
                      })),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () async {
                    final value = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateUtils.dateOnly(DateTime.now()),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)));
                    if (value != null) setState(() => _date = value);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat('yyyy/MM/dd').format(_date))),
              if (_type == 'closure')
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إغلاق اليوم كاملاً'),
                    value: _allDay,
                    onChanged: (v) => setState(() => _allDay = v)),
              if (!_allDay)
                Row(children: [
                  Expanded(
                      child: _TimeButton(
                          label: 'من',
                          time: _start,
                          onSelected: (v) => setState(() => _start = v))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _TimeButton(
                          label: 'إلى',
                          time: _end,
                          onSelected: (v) => setState(() => _end = v))),
                ]),
              TextField(
                  controller: _reason,
                  decoration:
                      const InputDecoration(labelText: 'السبب (اختياري)')),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () {
                if (!_allDay &&
                    _end.hour * 60 + _end.minute <=
                        _start.hour * 60 + _start.minute) return;
                Navigator.pop(
                    context,
                    _ExceptionFormValue(
                        _date, _type, _start, _end, _allDay, _reason.text));
              },
              child: const Text('حفظ')),
        ],
      );
}

class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          final query = _query.trim().toLowerCase();
          final students = state.students
              .where(
                (student) =>
                    student.fullName.toLowerCase().contains(query) ||
                    (student.phone ?? '').toLowerCase().contains(query) ||
                    (student.universityName ?? '')
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
          return ListView(padding: const EdgeInsets.all(20), children: [
            const _TabHeading(
                title: 'الطلاب', subtitle: 'ملفات الطلاب وعدد مواعيدهم.'),
            if (state.error != null) _ErrorBanner(message: state.error!),
            TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'ابحث بالاسم أو الهاتف أو الجامعة'),
                onChanged: (value) => setState(() => _query = value)),
            const SizedBox(height: 14),
            if (state.isLoading && state.students.isEmpty)
              const _LoadingPanel()
            else if (students.isEmpty)
              _EmptyPanel(
                  icon: Icons.people_outline,
                  title: query.isEmpty ? 'لا يوجد طلاب' : 'لا توجد نتائج',
                  subtitle: query.isEmpty
                      ? 'ستظهر حسابات الطلاب المسجلة هنا.'
                      : 'جرّب عبارة بحث أخرى.')
            else
              ...students.map((student) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: AppColors.cream,
                          child: Text(student.fullName.isEmpty
                              ? '?'
                              : student.fullName.substring(0, 1))),
                      title: Text(student.fullName),
                      subtitle: Text([
                        if (student.universityName?.isNotEmpty == true)
                          student.universityName!,
                        if (student.phone?.isNotEmpty == true) student.phone!,
                        if (student.studyYear?.isNotEmpty == true)
                          '${student.studyYear}${student.isGraduating ? ' · سنة تخرج' : ''}'
                      ].join(' · ')),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Chip(
                                label:
                                    Text('${student.appointmentsCount} موعد')),
                            IconButton(
                              tooltip: 'إضافة موعد',
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AdminDashboardCubit>(),
                                  child:
                                      CreateAppointmentDialog(student: student),
                                ),
                              ),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.forest),
                            ),
                          ]),
                    ),
                  )),
          ]);
        },
      );
}

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _maps = TextEditingController();
  final _duration = TextEditingController();
  int? _lastSettingsHash;
  int _horizon = 7;
  int _hold = 24;

  @override
  void dispose() {
    _address.dispose();
    _maps.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _sync(AdminAppSettings settings) {
    if (_lastSettingsHash == settings.hashCode) return;
    _lastSettingsHash = settings.hashCode;
    _address.text = settings.locationAddress;
    _maps.text = settings.locationMapsUrl ?? '';
    _duration.text = settings.lessonDurationLabel;
    _horizon = settings.bookingHorizonDays;
    _hold = settings.pendingHoldHours;
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          final settings = state.settings;
          if (settings != null) _sync(settings);
          return ListView(padding: const EdgeInsets.all(20), children: [
            const _TabHeading(
                title: 'إعدادات التطبيق',
                subtitle:
                    'تُحفظ هذه القيم في app_settings ويقرأها التطبيق عند الحاجة.'),
            if (state.isLoading && settings == null)
              const _LoadingPanel()
            else if (settings == null)
              _ErrorBanner(message: state.error ?? 'تعذر تحميل إعدادات التطبيق')
            else
              Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                            controller: _address,
                            decoration:
                                const InputDecoration(labelText: 'عنوان الدرس'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'العنوان مطلوب'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _maps,
                            decoration: const InputDecoration(
                                labelText: 'رابط الموقع على الخريطة'),
                            keyboardType: TextInputType.url,
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final uri = Uri.tryParse(v);
                              return uri != null &&
                                      uri.hasScheme &&
                                      uri.host.isNotEmpty
                                  ? null
                                  : 'أدخل رابطاً صحيحاً';
                            }),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _duration,
                            decoration: const InputDecoration(
                                labelText: 'وصف مدة الدرس'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'الوصف مطلوب'
                                : null),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                            value: _horizon,
                            decoration: const InputDecoration(
                                labelText: 'أفق الحجز بالأيام'),
                            items: List.generate(60, (i) => i + 1)
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text('$v يوم')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _horizon = v ?? _horizon)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                            value: _hold,
                            decoration: const InputDecoration(
                                labelText: 'مهلة الطلب المعلق بالساعات'),
                            items: List.generate(168, (i) => i + 1)
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text('$v ساعة')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _hold = v ?? _hold)),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: state.isBusy
                              ? null
                              : () async {
                                  if (!_form.currentState!.validate()) return;
                                  final ok = await context
                                      .read<AdminDashboardCubit>()
                                      .updateSettings(AdminAppSettings(
                                        locationAddress: _address.text,
                                        locationMapsUrl: _maps.text,
                                        bookingHorizonDays: _horizon,
                                        pendingHoldHours: _hold,
                                        lessonDurationLabel: _duration.text,
                                      ));
                                  if (context.mounted) _showResult(context, ok);
                                },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('حفظ الإعدادات'),
                        ),
                      ])),
            if (state.error != null) _ErrorBanner(message: state.error!),
          ]);
        },
      );
}

class _TabHeading extends StatelessWidget {
  const _TabHeading(
      {required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: _pageTitle),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              ]),
              if (trailing != null) trailing!,
            ]),
      );
}

const _pageTitle = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary);

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending' => ('معلق', AppColors.pendingBg, AppColors.pendingFg),
      'confirmed' => ('مؤكد', AppColors.confirmedBg, AppColors.confirmedFg),
      'rejected' => ('مرفوض', AppColors.rejectedBg, AppColors.rejectedFg),
      'cancelled' => ('ملغى', AppColors.neutralBg, AppColors.neutralFg),
      'completed' => ('مكتمل', AppColors.confirmedBg, AppColors.confirmedFg),
      'no_show' => ('لم يحضر', AppColors.rejectedBg, AppColors.rejectedFg),
      'expired' => ('منتهي', AppColors.neutralBg, AppColors.neutralFg),
      'cancellation_requested' => (
          'طلب إلغاء',
          AppColors.pendingBg,
          AppColors.pendingFg
        ),
      'reschedule_requested' => (
          'طلب تعديل',
          AppColors.pendingBg,
          AppColors.pendingFg
        ),
      _ => (status, AppColors.neutralBg, AppColors.neutralFg),
    };
    return Chip(
        label: Text(label, style: TextStyle(color: fg, fontSize: 12)),
        backgroundColor: bg,
        visualDensity: VisualDensity.compact);
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton(
      {required this.label, required this.time, required this.onSelected});
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onSelected;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () async {
          final value =
              await showTimePicker(context: context, initialTime: time);
          if (value != null) onSelected(value);
        },
        icon: const Icon(Icons.schedule_outlined),
        label: Text('$label ${time.format(context)}'),
      );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Icon(icon, size: 32, color: AppColors.sage),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
        ]),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.rejectedBg,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error))),
        ]),
      );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});
  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
            controller: _controller,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'ملاحظة أو سبب (اختياري)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('تأكيد')),
        ],
      );
}

Future<String?> _reasonDialog(BuildContext context, {required String title}) =>
    showDialog<String>(
        context: context, builder: (_) => _ReasonDialog(title: title));

void _showResult(BuildContext context, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok
        ? 'تم تنفيذ العملية بنجاح'
        : context.read<AdminDashboardCubit>().state.error ??
            'تعذر تنفيذ العملية'),
    backgroundColor: ok ? AppColors.primary : AppColors.error,
  ));
}

String _timeString(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
