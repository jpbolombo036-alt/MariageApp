import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

/// Ligne d'un invitÃÂ© (avatar, nom, statut RSVP, nb pers., icÃÂ´ne).
class AppGuestTile extends StatelessWidget {
  const AppGuestTile({
    super.key,
    required this.name,
    this.subtitle,
    this.statusLabel,
    this.statusIcon,
    this.statusColor = OrganizerColors.muted,
    this.statusBg = OrganizerColors.mutedBg,
    this.personsText,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final String? statusLabel;
  final IconData? statusIcon;
  final Color statusColor;
  final Color statusBg;
  final String? personsText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.subtle(scheme.shadow),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                   style: AppTypography.subtitle(
                     color: scheme.primary,
                   ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                       style: AppTypography.subtitle(
                         color: scheme.onSurface,
                       ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                         style: AppTypography.small(
                           color: scheme.onSurface.withValues(alpha: 0.55),
                         ),
                      ),
                    ],
                    if (statusLabel != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (statusIcon != null) ...[
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            statusLabel!,
                            style: AppTypography.small(color: statusColor)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (personsText != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              personsText!,
                               style: AppTypography.small(
                                 color: scheme.onSurface.withValues(alpha: 0.6),
                               ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: OrganizerColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
