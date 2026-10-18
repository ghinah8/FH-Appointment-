import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';

/// صفحة مؤقتة بعد تسجيل الدخول — تُستبدل بصفحة المواعيد المتاحة (للطالب)
/// ولوحة المعلومات (للمديرة) في الخطوة التالية.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          user == null
              ? ''
              : 'أهلاً ${user.fullName} — ${user.isAdmin ? 'لوحة الإدارة' : 'حساب طالب'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
