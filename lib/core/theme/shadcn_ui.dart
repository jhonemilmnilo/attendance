import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// App Theme Colors matching a modern, premium Shadcn UI design
class AppColors {
  static const Color primary = Color(0xFF09090B);
  static const Color primaryForeground = Color(0xFFFAFAFA);
  static const Color secondary = Color(0xFFF4F4F5);
  static const Color secondaryForeground = Color(0xFF18181B);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceForeground = Color(0xFF09090B);
  static const Color border = Color(0xFFE4E4E7);
  static const Color input = Color(0xFFE4E4E7);
  static const Color ring = Color(0xFF18181B);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFAFAFA);
  static const Color muted = Color(0xFFF4F4F5);
  static const Color mutedForeground = Color(0xFF71717A);
  static const Color accent = Color(0xFFF4F4F5);
  static const Color accentForeground = Color(0xFF18181B);
  static const Color success = Color(0xFF10B981);
  static const Color successForeground = Color(0xFFFAFAFA);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Premium Gradients
  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFAFA), Color(0xFFF4F4F5), Color(0xFFE4E4E7)],
  );
}

/// Glassmorphic Card Decoration
BoxDecoration glassDecoration({double blur = 12.0, double opacity = 0.7}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(opacity),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

/// App Theme
final colorScheme = ShadColorScheme(
  background: AppColors.background,
  foreground: AppColors.primary,
  card: AppColors.surface,
  cardForeground: AppColors.surfaceForeground,
  popover: AppColors.surface,
  popoverForeground: AppColors.surfaceForeground,
  primary: AppColors.primary,
  primaryForeground: AppColors.primaryForeground,
  secondary: AppColors.secondary,
  secondaryForeground: AppColors.secondaryForeground,
  muted: AppColors.muted,
  mutedForeground: AppColors.mutedForeground,
  accent: AppColors.accent,
  accentForeground: AppColors.accentForeground,
  destructive: AppColors.destructive,
  destructiveForeground: AppColors.destructiveForeground,
  border: AppColors.border,
  input: AppColors.input,
  ring: AppColors.ring,
  selection: AppColors.info,
);

final shadTheme = ShadThemeData(
  brightness: Brightness.light,
  colorScheme: colorScheme,
  textTheme: ShadTextTheme(family: 'Inter'),
);

// Fallback Material Theme for components not yet migrated
final materialTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.primaryForeground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryForeground,
    surface: AppColors.surface,
    onSurface: AppColors.primary,
    outline: AppColors.border,
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
  ),
);
