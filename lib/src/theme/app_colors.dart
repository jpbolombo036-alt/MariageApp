import 'package:flutter/material.dart';

/// Palette de couleurs centrale de MariagePlus (écran de connexion + au-delà).
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

  // --- Couleurs de l'espace AGENT_ACCUEIL ---

  /// Bleu marine principal de l'espace agent.
  static const Color agentNavy = Color(0xFF14213D);

  /// Or principal de l'espace agent.
  static const Color agentGold = Color(0xFFC99318);

  /// Or clair (dégradés / détails).
  static const Color agentGoldLight = Color(0xFFE5B84B);

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