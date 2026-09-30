import 'package:flutter/material.dart';

/// DESIGN SYSTEM — rôle GESTIONNAIRE_INVITES (EventiaEasy).
/// Palette dédiée clair/sombre, indépendante des autres rôles.
abstract final class GiColors {
  // Commun
  static const Color primary = Color(0xFF5B2DBD);
  static const Color primaryDeep = Color(0xFF45219B);

  /// Intermédiaire du dégradé du bandeau profil.
  static const Color primaryMid = Color(0xFF6D45D8);
  static const Color primaryLightBg = Color(0xFFEEE8FF);

  // Clair
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE8EAF0);

  // Sombre
  static const Color darkBackground = Color(0xFF0B1425);
  static const Color darkSurface = Color(0xFF172238);
  static const Color darkSurfaceAlt = Color(0xFF19253B);
  static const Color darkBorder = Color(0xFF26334A);
  static const Color darkTextPrimary = Color(0xFFF3F6FB);
  static const Color darkTextSecondary = Color(0xFFB6C0D1);
  static const Color darkPrimary = Color(0xFF7651E6);
  static const Color darkPrimaryBright = Color(0xFF8B6CFF);

  static const Color darkPrimaryLightBg = Color(0xFF2A1F4E);
  static const Color darkWarningBg = Color(0xFF3D2E0A);
  static const Color darkDangerBg = Color(0xFF3D1520);
  static const Color darkSuccessBg = Color(0xFF0A3D24);

  // Statuts / accents
  static const Color success = Color(0xFF22A06B);
  static const Color successBg = Color(0xFFEAF8F0);
  static const Color warning = Color(0xFFE88B16);
  static const Color warningBg = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFE05263);
  static const Color dangerBg = Color(0xFFFFF0F2);
  static const Color qrBlue = Color(0xFF2F80D1);
  static const Color profileTeal = Color(0xFF27A6B2);
}

abstract final class GiRadius {
  static const double card = 16;
  static const double stat = 16;
  static const double button = 14;
  static const double field = 14;
  static const double avatar = 48;
  static const double miniImage = 12;
}

class GiPalette {
  const GiPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.fieldFill,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryBright,
    required this.iconTint,
    required this.primaryLightBg,
    required this.warningBg,
    required this.dangerBg,
    required this.successBg,
    required this.danger,
    required this.warning,
    required this.success,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color fieldFill;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryBright;
  final Color iconTint;
  final Color primaryLightBg;
  final Color warningBg;
  final Color dangerBg;
  final Color successBg;
  final Color danger;
  final Color warning;
  final Color success;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  factory GiPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GiPalette(
      isDark: dark,
      background:
          dark ? GiColors.darkBackground : GiColors.lightBackground,
      surface: dark ? GiColors.darkSurface : GiColors.lightSurface,
      surfaceAlt: dark ? GiColors.darkSurfaceAlt : GiColors.lightSurface,
      fieldFill: dark ? GiColors.darkBackground : const Color(0xFFF1F3F8),
      border: dark ? GiColors.darkBorder : GiColors.lightBorder,
      textPrimary:
          dark ? GiColors.darkTextPrimary : GiColors.lightTextPrimary,
      textSecondary:
          dark ? GiColors.darkTextSecondary : GiColors.lightTextSecondary,
      primary: dark ? GiColors.darkPrimary : GiColors.primary,
      primaryBright: dark ? GiColors.darkPrimaryBright : GiColors.primary,
      iconTint: dark ? GiColors.darkTextSecondary : GiColors.lightTextSecondary,
      primaryLightBg:
          dark ? GiColors.darkPrimaryLightBg : GiColors.primaryLightBg,
      warningBg: dark ? GiColors.darkWarningBg : GiColors.warningBg,
      dangerBg: dark ? GiColors.darkDangerBg : GiColors.dangerBg,
      successBg: dark ? GiColors.darkSuccessBg : GiColors.successBg,
      danger: GiColors.danger,
      warning: GiColors.warning,
      success: GiColors.success,
    );
  }
}