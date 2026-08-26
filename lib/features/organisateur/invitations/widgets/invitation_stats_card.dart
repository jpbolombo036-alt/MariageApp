import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Petite capsule de statistique (Acceptées, Refusées, En attente, Annulées).
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(InvRadius.field),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$value', style: InvType.cardBody(color).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label, style: InvType.badge(color)),
        ],
      ),
    );
  }
}

/// Grande carte de statistiques d'invitations (total + grille 2x2).
class InvitationStatsCard extends StatelessWidget {
  const InvitationStatsCard({
    super.key,
    required this.total,
    required this.accepted,
    required this.declined,
    required this.pending,
    required this.cancelled,
  });

  final int total;
  final int accepted;
  final int declined;
  final int pending;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    const ok = Color(0xFF1E7A46);
    const ko = Color(0xFFB3382E);
    const wait = Color(0xFFA86A1E);
    const none = Color(0xFF5A6472);
    return Container(
      padding: const EdgeInsets.all(InvSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.card),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          // Partie gauche : icône enveloppe + total.
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: InvColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mail_outline, size: 22, color: InvColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$total', style: InvType.statValue(p.textPrimary)),
                    Text('Total', style: InvType.statLabel(p.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 72, color: p.border),
          const SizedBox(width: 16),
          // Partie droite : grille 2x2.
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _StatChip(label: 'Acceptées', value: accepted, color: ok),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Refusées', value: declined, color: ko),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _StatChip(label: 'En attente', value: pending, color: wait),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Annulées', value: cancelled, color: none),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}