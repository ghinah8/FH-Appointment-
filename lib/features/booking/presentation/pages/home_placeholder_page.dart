import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/di/injection.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/public_app_settings_cubit.dart';
import 'admin_home_page.dart';
import 'student_home_page.dart';

/// Selects the home experience for the authenticated user's role.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user.isAdmin) return AdminHomePage(user: user);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<BookingCubit>()..loadSlots()),
        BlocProvider(create: (_) => sl<PublicAppSettingsCubit>()..load()),
      ],
      child: StudentHomePage(user: user),
    );
  }
}
