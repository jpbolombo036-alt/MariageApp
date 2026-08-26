import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

/// Barre de recherche d'invité (espace AGENT_ACCUEIL).
class GuestSearchBar extends StatelessWidget {
  const GuestSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lightBorder, width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.agentTextSecondary, size: 24),
            SizedBox(width: 12),
            Text(
              'Rechercher un invité...',
              style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}