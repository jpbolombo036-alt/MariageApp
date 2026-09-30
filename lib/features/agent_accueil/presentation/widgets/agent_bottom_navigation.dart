import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

enum AgentTab { home, guests, scanner, attendance, profile }

/// Barre de navigation inférieure de l'espace AGENT_ACCUEIL,
/// avec bouton central "Scanner" mis en évidence.
class AgentBottomNavigation extends StatelessWidget {
  const AgentBottomNavigation({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AgentTab current;
  final ValueChanged<AgentTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return BottomAppBar(
      color: p.surface,
      elevation: 8,
      height: 72,
      padding: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border, width: 1)),
        ),
        child: Row(
          children: [
            _navItem(context, AgentTab.home, Icons.home_outlined, Icons.home, 'Accueil'),
            _navItem(context, AgentTab.guests, Icons.group_outlined, Icons.group, 'Invités'),
            _scannerCenter(p),
            _navItem(context, AgentTab.attendance, Icons.event_available_outlined, Icons.event_available, 'Présences'),
            _navItem(context, AgentTab.profile, Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, AgentTab tab, IconData icon, IconData activeIcon, String label) {
    final p = AgentPalette.of(context);
    final selected = current == tab;
    final color = selected ? p.primary : p.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(tab),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scannerCenter(AgentPalette p) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: GestureDetector(
        onTap: () => onSelect(AgentTab.scanner),
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [p.primary, p.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}