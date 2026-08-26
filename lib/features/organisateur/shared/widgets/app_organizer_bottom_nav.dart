import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

enum OrganizerTab { home, guests, add, calendar, more }

/// Navigation infÃ©rieure ORGANISATEUR avec bouton central + (crÃ©ation).
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
    return BottomAppBar(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(context, OrganizerTab.home, Icons.home_outlined, 'Accueil'),
            _item(context, OrganizerTab.guests, Icons.group_outlined, 'Invités'),
            _buildAddButton(context),
            _item(context, OrganizerTab.calendar, Icons.calendar_month_outlined, 'Calendrier'),
            _item(context, OrganizerTab.more, Icons.more_horiz, 'Plus'),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, OrganizerTab tab, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = current == tab;
    return InkWell(
      onTap: () => onSelect(tab),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5), size: 24),
          const SizedBox(height: 2),
          Text(
            label,
             style: AppTypography.small(
               color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
             ),
          ),
        ],
      ),
    );
  }

  /// Bouton central "+" surélevé qui déclenche la création d'un événement.
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(OrganizerTab.add),
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4E249E), Color(0xFF6B38D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B38D0).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
