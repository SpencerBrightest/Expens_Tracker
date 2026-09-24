import 'package:flutter/material.dart';

/// Ndoh flat palette — exclusively from Stitch exports (DESIGN.md).
/// No gradients anywhere. Use only these, never Flutter defaults.
abstract final class AppColors {
  static const primary = Color(0xFF2D68FE);
  static const primaryDeep = Color(0xFF004EDD);
  static const primaryFixed = Color(0xFFDCE1FF);
  static const primaryFixedDim = Color(0xFFB5C4FF);

  static const background = Color(0xFFF8F9FD);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF2F3FF);
  static const surfaceContainer = Color(0xFFECEDFA);
  static const surfaceHigh = Color(0xFFE6E7F4);
  static const surfaceHighest = Color(0xFFE0E2EE);

  static const success = Color(0xFF2EC771);
  static const successDeep = Color(0xFF006D38);
  static const successContainer = Color(0xFF6CFA9E);
  static const expense = Color(0xFFFA5A36);
  static const expenseDeep = Color(0xFFB12603);
  static const expenseContainer = Color(0xFFD43F1D);

  // Categorical accents
  static const coral = Color(0xFFFF6584);
  static const amber = Color(0xFFFFB800);
  static const purple = Color(0xFF6C5CE7);
  static const sky = Color(0xFF5D9CEC);

  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF8A92A6);
  static const onSurfaceVariant = Color(0xFF434655);
  static const border = Color(0xFFEEF2F6);
  static const outline = Color(0xFF737687);
  static const outlineVariant = Color(0xFFC3C5D8);
}
