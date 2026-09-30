import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

/// Barre de recherche d'invité (espace AGENT_ACCUEIL).
class GuestSearchBar extends StatelessWidget {
  const GuestSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: p.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher un invité',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}