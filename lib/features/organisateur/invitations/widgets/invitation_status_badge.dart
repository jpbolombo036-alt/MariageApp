import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Normalise un statut d'invitation (insensible à la casse / espaces).
String normStatus(String? raw) {
  if (raw == null) return '';
  return raw.trim().toUpperCase();
}

/// Libellé français d'un statut d'invitation.
/// NB : l'enum backend réel est DRAFT / GENERATED / SENT / CANCELLED / EXPIRED
/// (aucun statut RSVP au niveau invitation — le RSVP vit côté dashboard).
String invitationStatusLabel(String? raw) {
  switch (normStatus(raw)) {
    case 'DRAFT':
      return 'Brouillon';
    case 'GENERATED':
      return 'Générée';
    case 'SENT':
      return 'Envoyée';
    case 'CANCELLED':
    case 'CANCELED':
      return 'Annulée';
    case 'EXPIRED':
      return 'Expirée';
    default:
      return 'Générée';
  }
}

/// Libellé français d'un état RSVP (réponse du destinataire).
String rsvpLabel(String? raw) {
  switch (normStatus(raw)) {
    case 'ACCEPTED':
      return 'Confirmée';
    case 'DECLINED':
      return 'Refusée';
    case 'PENDING':
      return 'En attente';
    default:
      return 'En attente';
  }
}

/// Couleurs d'un badge de statut (fond translucide + texte lisible), adaptées
/// au mode clair/sombre.
class InvBadgeStyle {
  const InvBadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

InvBadgeStyle invitationStatusStyle(BuildContext context, String? raw) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (normStatus(raw)) {
    case 'SENT':
      return InvBadgeStyle(
        background: dark
            ? InvColors.successDarkBg.withValues(alpha: 0.9)
            : InvColors.successBg,
        foreground: dark ? InvColors.successOnDark : InvColors.success,
      );
    case 'DRAFT':
      return InvBadgeStyle(
        background: dark
            ? InvColors.infoDarkBg.withValues(alpha: 0.9)
            : InvColors.infoBg,
        foreground: dark ? InvColors.infoOnDark : InvColors.info,
      );
    case 'EXPIRED':
      return InvBadgeStyle(
        background: dark
            ? InvColors.warningDarkBg.withValues(alpha: 0.9)
            : InvColors.warningBg,
        foreground: dark ? InvColors.warningOnDark : InvColors.warning,
      );
    case 'CANCELLED':
    case 'CANCELED':
      return InvBadgeStyle(
        background: dark
            ? InvColors.dangerDarkBg.withValues(alpha: 0.9)
            : InvColors.dangerBg,
        foreground: dark ? InvColors.dangerOnDark : InvColors.danger,
      );
    default: // GENERATED et valeurs inconnues
      return InvBadgeStyle(
        background: dark
            ? InvColors.generatedDarkBg.withValues(alpha: 0.9)
            : InvColors.generatedBg,
        foreground: dark ? InvColors.generatedOnDark : InvColors.primary,
      );
  }
}

/// Badge de statut d'invitation.
class InvitationStatusBadge extends StatelessWidget {
  const InvitationStatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  final String? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final s = invitationStatusStyle(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(InvRadius.badge),
      ),
      child: Text(
        label ?? invitationStatusLabel(status),
        style: InvType.badge(s.foreground),
      ),
    );
  }
}