import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_shell.dart';
import '../cubit/login_cubit.dart' show FormStatus;
import '../cubit/verify_email_cubit.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<VerifyEmailCubit, ({FormStatus status, String? message})>(
      listener: (context, s) {
        if (s.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.message!)));
        }
      },
      builder: (context, s) {
        return AuthShell(
          quote: '«بداية كل رحلة\nخطوة واحدة»',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 56, color: AppColors.forest),
              const SizedBox(height: 20),
              Text('تحقق من بريدك الإلكتروني',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                email == null
                    ? 'أرسلنا رابط التفعيل إلى بريدك الإلكتروني. اضغط عليه لتفعيل حسابك ثم سجّل الدخول.'
                    : 'أرسلنا رابط التفعيل إلى $email\nاضغط عليه لتفعيل حسابك ثم سجّل الدخول. لا يمكن الحجز قبل التفعيل.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.muted, height: 1.7),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('الذهاب إلى تسجيل الدخول'),
              ),
              const SizedBox(height: 12),
              if (email != null)
                OutlinedButton(
                  onPressed: s.status == FormStatus.loading
                      ? null
                      : () => context.read<VerifyEmailCubit>().resend(email!),
                  child: s.status == FormStatus.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('إعادة إرسال الرابط'),
                ),
            ],
          ),
        );
      },
    );
  }
}
