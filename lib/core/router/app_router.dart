import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/register_cubit.dart';
import '../../features/auth/presentation/cubit/verify_email_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/booking/presentation/pages/home_placeholder_page.dart';
import '../di/injection.dart';

abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const home = '/home';

  static const _public = {login, register, verifyEmail};
}

/// يحوّل Stream إلى Listenable ليعيد GoRouter تقييم الـ redirect عند تغيّر الجلسة.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit auth) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _RouterRefresh(auth.stream),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final s = auth.state;

      switch (s.status) {
        case AuthStatus.unknown:
          return loc == Routes.splash ? null : Routes.splash;

        case AuthStatus.unauthenticated:
          return Routes._public.contains(loc) ? null : Routes.login;

        case AuthStatus.authenticated:
          // حساب غير موثّق البريد لا يستخدم التطبيق (حماية إضافية؛ الحجز يُمنع أيضاً في الخادم)
          if (!s.user!.emailConfirmed) {
            return loc == Routes.verifyEmail ? null : Routes.verifyEmail;
          }
          if (loc == Routes.splash || Routes._public.contains(loc)) {
            return Routes.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => BlocProvider(
          create: (_) => sl<LoginCubit>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => BlocProvider(
          create: (_) => sl<RegisterCubit>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<VerifyEmailCubit>(),
          child: VerifyEmailPage(email: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomePlaceholderPage(),
      ),
    ],
  );
}
