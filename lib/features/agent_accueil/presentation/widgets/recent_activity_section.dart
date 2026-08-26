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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.agentNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Voir tout',
                style: TextStyle(color: AppColors.agentGold, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucune activité récente',
              style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 14),
            ),
          )
        else
          for (final item in items) _itemCard(item),
      ],
    );
  }

  Widget _itemCard(RecentActivityItem item) {
    final initials = item.guestName.isEmpty
        ? '?'
        : item.guestName.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      height: 84,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.agentNavy,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.guestName,
                  style: const TextStyle(
                    color: AppColors.agentNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: AppColors.agentTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (item.time != null) ...[
            Text(
              item.time!,
              style: const TextStyle(color: AppColors.agentTextSecondary, fontSize: 13),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '✓ Présent',
              style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}