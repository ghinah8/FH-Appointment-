import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/labeled_inputs.dart';
import '../../domain/entities/study_year_option.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/login_cubit.dart' show FormStatus;
import '../cubit/register_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _universityId;
  StudyYearOption? _studyYear;
  bool _accepted = false;
  bool _acceptedError = false;

  @override
  void initState() {
    super.initState();
    context.read<RegisterCubit>().loadUniversities();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    setState(() => _acceptedError = !_accepted);
    if (!valid || !_accepted) return;

    context.read<RegisterCubit>().submit(SignUpData(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
          phone: Validators.normalizePhone(_phone.text),
          universityId: _universityId!,
          studyYear: _studyYear!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<RegisterCubit, RegisterState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == FormStatus.success && state.needsVerification) {
          context.go('/verify-email', extra: _email.text.trim());
        }
        // إن كان التحقق من البريد معطّلاً في Supabase تُنشأ جلسة مباشرة
        // ويوجّه الراوتر المستخدم إلى /home تلقائياً.
      },
      builder: (context, state) {
        final loading = state.status == FormStatus.loading;

        return AuthShell(
          quote: '«تعلّم اليوم\nلتبني غداً أجمل»',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إنشاء حساب جديد',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('املأ البيانات التالية لإنشاء حسابك',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'الاسم الكامل',
                  controller: _name,
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'الاسم الكامل'),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'البريد الإلكتروني',
                  controller: _email,
                  hint: 'name@example.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'رقم الهاتف (مع رمز الدولة)',
                  controller: _phone,
                  hint: '+963 9xx xxx xxx',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phoneWithCountryCode,
                ),
                const SizedBox(height: 14),
                LabeledDropdown<String>(
                  label: 'الجامعة',
                  hint: 'اختر الجامعة',
                  loading: state.universitiesLoading,
                  value: _universityId,
                  items: [
                    for (final u in state.universities)
                      DropdownMenuItem(value: u.id, child: Text(u.name)),
                  ],
                  onChanged: (v) => setState(() => _universityId = v),
                  validator: (v) => v == null ? 'اختر الجامعة' : null,
                ),
                const SizedBox(height: 14),
                LabeledDropdown<StudyYearOption>(
                  label: 'السنة الدراسية',
                  hint: 'اختر السنة الدراسية',
                  value: _studyYear,
                  items: [
                    for (final y in StudyYearOption.values)
                      DropdownMenuItem(value: y, child: Text(y.label)),
                  ],
                  onChanged: (v) => setState(() => _studyYear = v),
                  validator: (v) => v == null ? 'اختر السنة الدراسية' : null,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'كلمة المرور',
                  controller: _password,
                  hint: '8 أحرف على الأقل',
                  obscure: true,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'تأكيد كلمة المرور',
                  controller: _confirm,
                  obscure: true,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: Validators.matches(() => _password.text),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => setState(() {
                    _accepted = !_accepted;
                    _acceptedError = false;
                  }),
                  child: Row(children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (v) => setState(() {
                        _accepted = v ?? false;
                        _acceptedError = false;
                      }),
                    ),
                    Expanded(
                      child: Text('أوافق على الشروط والأحكام',
                          style: theme.textTheme.bodyMedium),
                    ),
                  ]),
                ),
                if (_acceptedError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 12),
                    child: Text('يجب الموافقة على الشروط للمتابعة',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error)),
                  ),
                if (state.status == FormStatus.failure && state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(state.error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('متابعة'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لديك حساب بالفعل؟',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.muted)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('تسجيل الدخول'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
