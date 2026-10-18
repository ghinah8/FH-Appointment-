import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// شعار مؤقت نصّي (FH + FATIMA HABIB) إلى حين اعتماد ملف الشعار النهائي.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.color = Colors.white, this.size = 56});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'FH',
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w200,
              letterSpacing: 2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'FATIMA HABIB',
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: size * 0.2,
              letterSpacing: size * 0.12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// هيكل صفحات الدخول والتسجيل: لوحة خضراء داكنة + بطاقة النموذج.
/// على الشاشات العريضة: النموذج يمين واللوحة يسار (RTL). على الموبايل: شريط علوي.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.quote, required this.child});

  final String quote;
  final Widget child;

  static const _breakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _breakpoint;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: child,
        ),
      ),
    );

    if (!wide) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: const Center(child: BrandMark(size: 40)),
              ),
              Expanded(child: form),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 6, child: form),
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  const BrandMark(size: 72),
                  const Spacer(flex: 3),
                  Text(
                    quote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.cream,
                          height: 1.7,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.eco_outlined,
                      color: AppColors.sage, size: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
