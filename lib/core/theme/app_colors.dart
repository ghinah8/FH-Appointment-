import 'package:flutter/material.dart';

/// ألوان التصميم (من لوحة "الألوان الأساسية" في اللوحة المعتمدة)
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF0F2A1D); // أخضر داكن جداً
  static const forest = Color(0xFF375534);
  static const sage = Color(0xFF6B9071);
  static const mist = Color(0xFFAEC3B0);
  static const cream = Color(0xFFE3EED4);

  static const background = Color(0xFFF4F6F1);
  static const surface = Colors.white;
  static const border = Color(0xFFDCE4D8);

  static const text = Color(0xFF14261B);
  static const muted = Color(0xFF6A7A6F);
  static const error = Color(0xFFB3402F);

  // حالات الحجز
  static const confirmedBg = Color(0xFFDDEBDD);
  static const confirmedFg = Color(0xFF2F5A3A);
  static const pendingBg = Color(0xFFFFF0D6);
  static const pendingFg = Color(0xFF8A5A00);
  static const rejectedBg = Color(0xFFFBE0DC);
  static const rejectedFg = Color(0xFF9B2F22);
  static const neutralBg = Color(0xFFE9ECE7);
  static const neutralFg = Color(0xFF55615A);
}
