import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';
import 'invitation_status_badge.dart';

/// Carte d'une invitation dans la liste (reproduit la maquette de référence).
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.guestName,
    this.avatarInitial,
    this.subtitle,
    this.maxPersons,
    required this.status,
    this.metaLeft,
    this.metaLeftIcon = Icons.calendar_today_outlined,
    this.metaRight,
    this.onTap,
    this.onMenu,
  });

  final String guestName;
  final String? avatarInitial;
  final String? subtitle;
  final int? maxPersons;
  final String? status;
  final String? metaLeft;
  final IconData metaLeftIcon;
  final String? metaRight;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  static String initialFor(String name) =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InvRadius.card),
        child: Container(
          padding: const EdgeInsets.all(InvSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(InvRadius.card),
            border: Border.all(color: p.border),
            boxShadow: p.cardShadow,
          ),
          child: Column(
            children: [
              _topRow(context),
              const SizedBox(height: 10),
              Divider(height: 1, color: p.border),
              const SizedBox(height: 8),
              _bottomRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context) {
    final p = InvPalette.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: InvColors.primaryLight,
          child: Text(
            avatarInitial ?? initialFor(guestName),
            style: InvType.cardBody(InvColors.primaryDark)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guestName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: InvType.guestName(p.textPrimary),
              ),
              if (maxPersons != null) ...[
                const SizedBox(height: 3),
                Text(
                  maxPersons! > 1
                      ? '$maxPersons personnes max'
                      : '1 personne max',
                  style: InvType.cardMuted(p.textSecondary),
                ),
              ],
            ],
          ),
        ),
        InvitationStatusBadge(status: status),
        const SizedBox(width: 4),
        if (onMenu != null)
          InkResponse(
            onTap: onMenu,
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.more_vert, size: 20, color: p.icon),
            ),
          ),
      ],
    );
  }

  Widget _bottomRow(BuildContext context) {
    final p = InvPalette.of(context);
    return Row(
      children: [
        Icon(metaLeftIcon, size: 16, color: p.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            metaLeft ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: InvType.cardMuted(p.textSecondary),
          ),
        ),
        if (metaRight != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.people_outline, size: 16, color: p.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              metaRight!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InvType.cardMuted(p.textSecondary),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, size: 20, color: p.textTertiary),
      ],
    );
  }
}