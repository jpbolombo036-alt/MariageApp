import 'package:flutter/material.dart';

import '../../../src/theme/gi_ui.dart';
import 'gi_header_stats.dart';
import 'gi_nav.dart';

/// Grille « Mes modules » du rôle GESTIONNAIRE_INVITES (3×2).
/// Les callbacks sont fournis par l'écran hôte.
class GiModulesGrid extends StatelessWidget {
  const GiModulesGrid({super.key, this.onTap});

  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Mes modules',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GiPalette.of(context).textPrimary)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .82,
        children: [
          GiModuleCard(
              icon: Icons.group,
              title: 'Invités',
              subtitle: 'Gérer la liste des invités',
              color: GiPalette.of(context).primary,
              onTap: () => onTap?.call(0)),
          GiModuleCard(
              icon: Icons.mail_outline,
              title: 'Invitations',
              subtitle: 'Créer et suivre les invitations',
              color: GiPalette.of(context).primary,
              onTap: () => onTap?.call(1)),
          GiModuleCard(
              icon: Icons.schedule,
              title: 'Réponses RSVP',
              subtitle: 'Voir les réponses des invités',
              color: GiColors.warning,
              onTap: () => onTap?.call(2)),
          GiModuleCard(
              icon: Icons.label_outline,
              title: 'Catégories',
              subtitle: 'Gérer les catégories d\u2019invités',
              color: GiColors.danger,
              onTap: () => onTap?.call(3)),
          GiModuleCard(
              icon: Icons.qr_code_2,
              title: 'QR Codes',
              subtitle: 'Voir et partager les QR Codes',
              color: GiColors.qrBlue,
              onTap: () => onTap?.call(4)),
          GiModuleCard(
              icon: Icons.person_outline,
              title: 'Mon profil',
              subtitle: 'Gestion de mon compte',
              color: GiColors.profileTeal,
              onTap: () => onTap?.call(5)),
        ],
      ),
    ]);
  }
}

/// Onglet « Plus » : pont vers le profil.
class GiMoreTab extends StatelessWidget {
  const GiMoreTab({super.key, this.onProfile});
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 48, color: p.primary),
              const SizedBox(height: 12),
              Text('Mon profil',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary)),
              const SizedBox(height: 8),
              Text('Gestion de mon compte et préférences',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 20),
              if (onProfile != null)
                SizedBox(
                  width: 220, height: 46,
                  child: GiPrimaryButton(
                      label: 'Ouvrir mon profil', onTap: onProfile),
                ),
            ]),
      ),
    );
  }
}