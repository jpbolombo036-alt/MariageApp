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
            ? const Color(0xFF1E3A2A).withValues(alpha: 0.9)
            : const Color(0xFFE7F6EC),
        foreground: dark
            ? const Color(0xFF7BE0A0)
            : const Color(0xFF1E7A46),
      );
    case 'DRAFT':
      return InvBadgeStyle(
        background: dark
            ? const Color(0xFF242E44).withValues(alpha: 0.9)
            : const Color(0xFFEDF1FB),
        foreground: dark
            ? const Color(0xFFA9BFF0)
            : const Color(0xFF4A5CA8),
      );
    case 'EXPIRED':
      return InvBadgeStyle(
        background: dark
            ? const Color(0xFF3A2E1C).withValues(alpha: 0.9)
            : const Color(0xFFFBF3E6),
        foreground: dark
            ? const Color(0xFFF0C07A)
            : const Color(0xFFA86A1E),
      );
    case 'CANCELLED':
    case 'CANCELED':
      return InvBadgeStyle(
        background: dark
            ? const Color(0xFF3A2026).withValues(alpha: 0.9)
            : const Color(0xFFFCEBE9),
        foreground: dark
            ? const Color(0xFFF2918A)
            : const Color(0xFFB3382E),
      );
    default: // GENERATED et valeurs inconnues
      return InvBadgeStyle(
        background: dark
            ? const Color(0xFF25203A).withValues(alpha: 0.9)
            : const Color(0xFFEFEBFF),
        foreground: dark
            ? const Color(0xFFC5B8F0)
            : const Color(0xFF5B2CCF),
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