import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

/// Entrée d'activité récente (un check-in).
class RecentActivityItem {
  const RecentActivityItem({
    required this.guestName,
    this.subtitle = 'Check-in enregistré',
    this.time,
  });

  final String guestName;
  final String subtitle;
  final String? time;
}

/// Section "Activité récente" de l'espace AGENT_ACCUEIL.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    super.key,
    required this.title,
    required this.onSeeAll,
    required this.items,
  });

  final String title;
  final VoidCallback onSeeAll;
  final List<RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Voir tout',
                style: TextStyle(color: p.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucune activité récente',
              style: TextStyle(color: p.textSecondary, fontSize: 14),
            ),
          )
        else
          for (final item in items) _itemCard(item, p),
      ],
    );
  }

  Widget _itemCard(RecentActivityItem item, AgentPalette p) {
    final words = item.guestName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : words.map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: p.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (item.time != null && item.time!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _shortTime(item.time!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: p.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Présent',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.length > 16 ? raw.substring(0, 16) : raw;
    }
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }
}