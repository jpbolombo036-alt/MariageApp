import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

enum OrganizerTab { home, guests, add, calendar, more }

/// Navigation inférieure ORGANISATEUR avec bouton central + (création).
class AppOrganizerBottomNav extends StatelessWidget {
  const AppOrganizerBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final OrganizerTab current;
  final ValueChanged<OrganizerTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _item(context, OrganizerTab.home, Icons.home_outlined,
                  Icons.home_rounded, 'Accueil'),
              _item(context, OrganizerTab.guests, Icons.group_outlined,
                  Icons.group_rounded, 'Invités'),
              _buildAddButton(context),
              _item(context, OrganizerTab.calendar, Icons.calendar_month_outlined,
                  Icons.calendar_month_rounded, 'Calendrier'),
              _item(context, OrganizerTab.more, Icons.more_horiz,
                  Icons.more_horiz, 'Plus'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    OrganizerTab tab,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = current == tab;
    final color = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.5);
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(tab),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.small(color: color).copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton central "+" surélevé qui déclenche la création d'un événement.
  Widget _buildAddButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(OrganizerTab.add),
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
