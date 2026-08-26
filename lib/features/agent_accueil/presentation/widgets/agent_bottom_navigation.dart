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
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 8,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.lightBorder, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(AgentTab.home, Icons.home_outlined, Icons.home, 'Accueil'),
            _navItem(AgentTab.guests, Icons.group_outlined, Icons.group, 'Invités'),
            _scannerCenter(),
            _navItem(AgentTab.attendance, Icons.event_available_outlined, Icons.event_available, 'Présences'),
            _navItem(AgentTab.profile, Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(AgentTab tab, IconData icon, IconData activeIcon, String label) {
    final selected = current == tab;
    final color = selected ? AppColors.agentNavy : AppColors.agentTextSecondary;
    return InkWell(
      onTap: () => onSelect(tab),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerCenter() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: GestureDetector(
        onTap: () => onSelect(AgentTab.scanner),
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.agentNavy, AppColors.agentGold],
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