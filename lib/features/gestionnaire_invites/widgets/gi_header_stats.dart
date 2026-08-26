import 'package:flutter/material.dart';

import '../../../../src/theme/gi_ui.dart';

/// Header compact du dashboard GESTIONNAIRE_INVITES.
class GiHeader extends StatelessWidget {
  const GiHeader({
    super.key,
    required this.firstName,
    this.subtitle = 'Gestion des invités de votre événement',
    this.onMenu,
    this.onNotifications,
  });

  final String firstName;
  final String subtitle;
  final VoidCallback? onMenu;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(10),
            child: Icon(Icons.menu, size: 24, color: p.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour, $firstName 👋',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 26, color: p.textPrimary),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: Color(0xFFE05263), shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carte statistique compacte (icône ronde + valeur + libellé).
class GiQuickStatCard extends StatelessWidget {
  const GiQuickStatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GiRadius.stat),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: p.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                  height: 1.0)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textSecondary)),
        ],
      ),
    );
  }
}

/// Carte module de la grille « Mes modules ».
class GiModuleCard extends StatelessWidget {
  const GiModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GiRadius.card),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(GiRadius.card),
            border: Border.all(color: p.border),
            boxShadow: p.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 10, color: p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}