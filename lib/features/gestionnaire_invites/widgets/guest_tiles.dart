import 'package:flutter/material.dart';

import '../../../src/theme/gi_ui.dart';

/// Badge de statut RSVP (valeurs backend : ACCEPTED / DECLINED / PENDING).
class RsvpStatusBadge extends StatelessWidget {
  const RsvpStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    switch ((status ?? '').toUpperCase().trim()) {
      case 'ACCEPTED':
        return _badge(context, 'Accepté', GiColors.successBg, GiColors.success);
      case 'DECLINED':
        return _badge(context, 'Refusé', GiColors.dangerBg, GiColors.danger);
      default:
        return _badge(
            context, 'En attente', GiColors.warningBg, GiColors.warning);
    }
  }

  Widget _badge(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: GiPalette.of(context).isDark ? fg.withValues(alpha: 0.18) : bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Ligne d'invité (liste + réponses RSVP).
class GuestListItem extends StatelessWidget {
  const GuestListItem({
    super.key,
    required this.name,
    this.subtitle,
    this.rsvpStatus,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final String? rsvpStatus;
  final VoidCallback? onTap;

  String get _initial {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GiRadius.card),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(GiRadius.card),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                 radius: 19,
                 backgroundColor: p.primaryLightBg,
                 child: Text(_initial,
                     style: TextStyle(
                         fontSize: 13,
                         fontWeight: FontWeight.w700,
                         color: p.primary)),
               ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 11, color: p.textSecondary)),
                    ],
                  ],
                ),
              ),
              RsvpStatusBadge(status: rsvpStatus),
              Icon(Icons.chevron_right, size: 20, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}