import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../../../../core/widgets/labeled_inputs.dart';
import '../cubit/login_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginCubit>().submit(_email.text, _password.text);
    }
  }

  Future<void> _forgotPassword() async {
    final cubit = context.read<LoginCubit>();
    final controller = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'البريد الإلكتروني'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email != null && Validators.email(email) == null) {
      cubit.sendPasswordReset(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        final msg = state.info;
        if (msg != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, state) {
        final loading = state.status == FormStatus.loading;

        return AuthShell(
          quote: '«بخطوة صغيرة اليوم،\nتصنع فرقاً كبيراً غداً»',
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تسجيل الدخول',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('مرحباً بعودتك! أدخل بياناتك للمتابعة',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 28),
                  LabeledField(
                    label: 'البريد الإلكتروني',
                    controller: _email,
                    hint: 'name@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledField(
                        label: 'كلمة المرور',
                        controller: _password,
                        hint: '••••••••',
                        icon: null,
                        obscure: _obscure,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            Validators.required(v, 'كلمة المرور'),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18),
                          label: Text(_obscure ? 'إظهار' : 'إخفاء'),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: loading ? null : _forgotPassword,
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
                  ),
                  if (state.status == FormStatus.failure &&
                      state.error != null) ...[
                    const SizedBox(height: 4),
                    _ErrorBox(message: state.error!),
                    if (state.needsVerification)
                      TextButton(
                        onPressed: () => context
                            .read<LoginCubit>()
                            .resendVerification(_email.text),
                        child: const Text('إعادة إرسال رسالة التحقق'),
                      ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('تسجيل الدخول'),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('أو',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: loading ? null : () => context.go('/register'),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لم يتم تفعيل الحساب؟ تحقق من بريدك الإلكتروني',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.rejectedFg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.rejectedFg)),
        ),
      ]),
    );
  }
}
