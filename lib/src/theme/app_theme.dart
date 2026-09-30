import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrganizerColors {
  OrganizerColors._();

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFEC4899);

  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF18181B);
  static const Color lightSecondary = Color(0xFF71717A);
  static const Color lightBorder = Color(0xFFE9E7EF);
  static const Color lightSurfaceViolet = Color(0xFFF3EEFF);

  /// Fond clair des champs de recherche et pastilles neutres.
  static const Color fieldFill = Color(0xFFF4F2FA);

  static const Color darkBackground = Color(0xFF121015);
  static const Color darkSurface = Color(0xFF1C1920);
  static const Color darkSurfaceSecondary = Color(0xFF26212A);
  static const Color darkText = Color(0xFFF8F7FC);
  static const Color darkSecondary = Color(0xFFAAA4B2);
  static const Color darkBorder = Color(0xFF342E39);

  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color muted = Color(0xFF71717A);
  static const Color mutedBg = Color(0xFFF3F4F6);

  /// Information / agenda (bleu).
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);

  /// Vert de marque WhatsApp (diffusion des invitations).
  static const Color whatsapp = Color(0xFF25D366);

  /// Variantes claires lisibles sur les héros violets (fond foncé).
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color warningOnDark = Color(0xFFFCD34D);

  /// Fond rose clair dérivé de la couleur d'accent (vignettes, badges).
  static const Color accentBg = Color(0xFFFCE7F3);
}

abstract final class AppTypography {
  static TextStyle display({Color? color}) => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle sectionTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle cardTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle subtitle({Color? color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle small({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle stat({Color? color}) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 22;
  static const double small = 12;
  static const double field = 14;
  static const double card = 18;
  static const double eventCard = 20;
  static const double button = 14;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

abstract final class AppShadows {
  static List<BoxShadow> subtle(Color shadowColor, {double blur = 14}) => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.06),
          blurRadius: blur,
          offset: const Offset(0, 6),
        ),
      ];
}

abstract final class AppTheme {
  static ThemeData get light => _build(const ColorScheme.light(
        primary: OrganizerColors.primary,
        secondary: OrganizerColors.accent,
        surface: OrganizerColors.lightSurface,
        onSurface: OrganizerColors.lightText,
        onPrimary: Colors.white,
        outline: OrganizerColors.lightBorder,
        error: OrganizerColors.danger,
      ));

  static ThemeData get dark => _build(const ColorScheme.dark(
        primary: OrganizerColors.primary,
        secondary: OrganizerColors.accent,
        surface: OrganizerColors.darkSurface,
        onSurface: OrganizerColors.darkText,
        onPrimary: Colors.white,
        outline: OrganizerColors.darkBorder,
        error: OrganizerColors.danger,
      ));

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? OrganizerColors.darkBackground : OrganizerColors.lightBackground,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: AppTypography.display(color: scheme.onSurface),
        titleLarge: AppTypography.cardTitle(color: scheme.onSurface),
        titleMedium: AppTypography.subtitle(color: scheme.onSurface),
        bodyMedium: AppTypography.body(color: scheme.onSurface),
        bodySmall: AppTypography.small(color: scheme.onSurface),
        labelLarge: AppTypography.button(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button(color: scheme.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? OrganizerColors.darkSurfaceSecondary : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: AppTypography.small(color: scheme.primary)
            .copyWith(fontWeight: FontWeight.w600),
        labelStyle: AppTypography.small(color: scheme.onSurface)
            .copyWith(fontWeight: FontWeight.w600),
        hintStyle: AppTypography.body(
          color: isDark ? OrganizerColors.darkSecondary : OrganizerColors.lightSecondary,
        ),
        prefixIconColor: isDark ? OrganizerColors.darkSecondary : OrganizerColors.lightSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? OrganizerColors.darkBorder : OrganizerColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? OrganizerColors.darkBorder : OrganizerColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: OrganizerColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: OrganizerColors.danger, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? OrganizerColors.darkBorder : OrganizerColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: isDark ? OrganizerColors.darkSurface : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? OrganizerColors.darkBorder : OrganizerColors.lightBorder,
          ),
        ),
      ),
    );
  }
}
