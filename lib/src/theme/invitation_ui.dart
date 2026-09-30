import 'package:flutter/material.dart';

/// ============================================================================
/// DESIGN SYSTEM — Module INVITATIONS (EventiaEasy)
/// ----------------------------------------------------------------------------
/// Centralise les couleurs, espacements, rayons et styles de texte du module.
/// Reproduit la maquette de référence (clair + sombre) SANS toucher aux
/// autres modules ni à la logique métier.
/// ============================================================================

/// Palette violette de référence.
abstract final class InvColors {
  static const Color primary = Color(0xFF5B2CCF);
  static const Color primaryDark = Color(0xFF4520A5);
  static const Color primaryMedium = Color(0xFF6C3BD2);
  static const Color primaryLight = Color(0xFFEEE8FF);
  static const Color primaryVeryLight = Color(0xFFF6F3FF);

  /// Dégradé du bouton principal (subtil).
  static const Color gradientStart = Color(0xFF6A3ED1);
  static const Color gradientEnd = Color(0xFF4B20B5);

  // --- Mode clair ---
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9EAF0);
  static const Color lightTextPrimary = Color(0xFF1D2330);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextTertiary = Color(0xFF98A2B3);
  static const Color lightIcon = Color(0xFF475467);

  // --- Mode sombre ---
  static const Color darkBackground = Color(0xFF0D1424);
  static const Color darkSurface = Color(0xFF151E2E);
  static const Color darkSurfaceSecondary = Color(0xFF192334);
  static const Color darkBorder = Color(0xFF263247);
  static const Color darkTextPrimary = Color(0xFFF7F8FA);
  static const Color darkTextSecondary = Color(0xFFA8B1C1);
  static const Color darkTextWeak = Color(0xFF7D8798);
  static const Color darkIcon = Color(0xFFC4CBD7);

  // --- Statuts des badges (fond + texte, mode clair / mode sombre) ---
  /// Envoyée / confirmée (vert).
  static const Color success = Color(0xFF1E7A46);
  static const Color successBg = Color(0xFFE7F6EC);
  static const Color successDarkBg = Color(0xFF1E3A2A);
  static const Color successOnDark = Color(0xFF7BE0A0);

  /// Brouillon / en attente (indigo).
  static const Color info = Color(0xFF4A5CA8);
  static const Color infoBg = Color(0xFFEDF1FB);
  static const Color infoDarkBg = Color(0xFF242E44);
  static const Color infoOnDark = Color(0xFFA9BFF0);

  /// Expirée (ambre).
  static const Color warning = Color(0xFFA86A1E);
  static const Color warningBg = Color(0xFFFBF3E6);
  static const Color warningDarkBg = Color(0xFF3A2E1C);
  static const Color warningOnDark = Color(0xFFF0C07A);

  /// Annulée / refusée (rouge).
  static const Color danger = Color(0xFFB3382E);
  static const Color dangerBg = Color(0xFFFCEBE9);
  static const Color dangerDarkBg = Color(0xFF3A2026);
  static const Color dangerOnDark = Color(0xFFF2918A);

  /// Générée (violet clair) : le texte clair réutilise [primary].
  static const Color generatedBg = Color(0xFFEFEBFF);
  static const Color generatedDarkBg = Color(0xFF25203A);
  static const Color generatedOnDark = Color(0xFFC5B8F0);

  /// Action destructive (boutons/textes « Supprimer »).
  static const Color destructive = Color(0xFFDC2626);

  /// Neutre (statistiques sans donnée).
  static const Color neutral = Color(0xFF5A6472);

  /// Pastille de notification (rouge vif) et vert WhatsApp (diffusion).
  static const Color notification = Color(0xFFED3A4A);
  static const Color whatsapp = Color(0xFF25D366);
}

/// Espacements du module invitations.
abstract final class InvSpacing {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Résolution de la palette selon le thème courant.
class InvPalette {
  const InvPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.icon,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color icon;

  /// Ombre de carte très légère.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  factory InvPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InvPalette(
      isDark: isDark,
      background: isDark ? InvColors.darkBackground : InvColors.lightBackground,
      surface: isDark ? InvColors.darkSurface : InvColors.lightSurface,
      surfaceSecondary:
          isDark ? InvColors.darkSurfaceSecondary : InvColors.primaryVeryLight,
      border: isDark ? InvColors.darkBorder : InvColors.lightBorder,
      textPrimary:
          isDark ? InvColors.darkTextPrimary : InvColors.lightTextPrimary,
      textSecondary:
          isDark ? InvColors.darkTextSecondary : InvColors.lightTextSecondary,
      textTertiary:
          isDark ? InvColors.darkTextWeak : InvColors.lightTextTertiary,
      icon: isDark ? InvColors.darkIcon : InvColors.lightIcon,
    );
  }
}

/// Dégradé violet du bouton principal.
const LinearGradient invPrimaryGradient = LinearGradient(
  colors: [InvColors.gradientStart, InvColors.gradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Styles de texte du module invitations (compacts et élégants).
abstract final class InvType {
  static TextStyle screenTitle(Color c) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: c,
      );

  static TextStyle appBarTitle(Color c) => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: c,
      );

  static TextStyle subtitle(Color c) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: c,
      );

  static TextStyle guestName(Color c) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: c,
      );

  static TextStyle guestNameStrong(Color c) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: c,
      );

  static TextStyle cardBody(Color c) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: c,
      );

  static TextStyle cardMuted(Color c) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: c,
      );

  static TextStyle badge(Color c) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: c,
      );

  static TextStyle button(Color c) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: c,
      );

  static TextStyle statValue(Color c) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: c,
      );

  static TextStyle statLabel(Color c) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: c,
      );
}

/// Rayons du module invitations.
abstract final class InvRadius {
  static const double card = 14;
  static const double button = 16;
  static const double field = 12;
  static const double badge = 10;
  static const double pill = 28;
}