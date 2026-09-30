import 'package:flutter/material.dart';

/// Palette de couleurs centrale d'EventiaEasy (écran de connexion + au-delà).
///
/// Source : maquette référence Login.
class AppColors {
  AppColors._();

  /// Bleu marine — textes principaux, icônes, parties "Mariage".
  static const Color primaryNavy = Color(0xFF1F2D45);

  /// Doré principal — bouton principal, liens, partie "Plus".
  static const Color gold = Color(0xFFB8860B);

  /// Doré clair — variations / dégradés subtils.
  static const Color goldLight = Color(0xFFC99A24);

  /// Fond général crème.
  static const Color background = Color(0xFFF8F6F1);

  /// Surface des cartes.
  static const Color surface = Color(0xFFFFFFFF);

  /// Texte secondaire.
  static const Color textSecondary = Color(0xFF647084);

  /// Placeholder des champs.
  static const Color textPlaceholder = Color(0xFF7B8798);

  /// Bordure des champs / boutons secondaires.
  static const Color border = Color(0xFFD5DAE2);

  /// Séparateur très léger.
  static const Color divider = Color(0xFFE8E8E8);

  // --- Mode sombre espace AGENT_ACCUEIL ---
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111B2D);
  static const Color darkSurfaceAlt = Color(0xFF162033);
  static const Color darkBorder = Color(0xFF253352);
  static const Color darkTextPrimary = Color(0xFFF3F6FB);
  static const Color darkTextSecondary = Color(0xFFB6C0D1);
  static const Color darkAgentGold = Color(0xFFA78BFA);
  static const Color darkAgentGoldLight = Color(0xFF8B5CF6);
  static const Color darkSuccessBg = Color(0xFF0A2E1C);
  static const Color darkDanger = Color(0xFFF0544C);

  // --- Couleurs de l'espace AGENT_ACCUEIL ---

  /// Bleu marine principal de l'espace agent.
  static const Color agentNavy = Color(0xFF14213D);

  /// Violet de la marque — même accent que le login et l’espace organisateur.
  static const Color agentGold = Color(0xFF7C3AED);

  /// Violet foncé — dégradés des boutons agent.
  static const Color agentGoldLight = Color(0xFF5B21B6);

  /// Vert succès (check-in réussi, invité présent, événement actif).
  static const Color success = Color(0xFF2E7D32);

  /// Vert très clair (badge de succès).
  static const Color successBg = Color(0xFFE8F5E9);

  /// Rouge erreur (QR invalide, accès refusé, invitation annulée).
  static const Color danger = Color(0xFFC62828);

  /// Texte secondaire générique de l'espace agent.
  static const Color agentTextSecondary = Color(0xFF6B7280);

  /// Bordure légère de recherche / cartes.
  static const Color lightBorder = Color(0xFFE5E7EB);
}

class AgentPalette {
  const AgentPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryLight,
    required this.successBg,
    required this.danger,
    required this.goldBright,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryLight;
  final Color successBg;
  final Color danger;
  final Color goldBright;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  factory AgentPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AgentPalette(
      isDark: dark,
      background: dark ? AppColors.darkBackground : AppColors.background,
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      surfaceAlt: dark ? AppColors.darkSurfaceAlt : AppColors.surface,
      border: dark ? AppColors.darkBorder : AppColors.lightBorder,
      textPrimary: dark ? AppColors.darkTextPrimary : AppColors.agentNavy,
      textSecondary: dark ? AppColors.darkTextSecondary : AppColors.agentTextSecondary,
      primary: dark ? AppColors.darkAgentGold : AppColors.agentGold,
      primaryLight: dark ? AppColors.darkAgentGoldLight : AppColors.agentGoldLight,
      successBg: dark ? AppColors.darkSuccessBg : AppColors.successBg,
      danger: dark ? AppColors.darkDanger : AppColors.danger,
      goldBright: dark ? AppColors.darkAgentGold : AppColors.agentGold,
    );
  }
}

/// Système d'espacements réutilisable.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}
