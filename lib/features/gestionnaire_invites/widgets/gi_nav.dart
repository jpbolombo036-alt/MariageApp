import 'package:flutter/material.dart';

import '../../../src/theme/gi_ui.dart';

enum GiTab { home, guests, add, invitations, more }

/// Bottom navigation GESTIONNAIRE_INVITES : Accueil · Invités · [+] · Invitations · Plus.
class GiBottomNav extends StatelessWidget {
  const GiBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final GiTab current;
  final ValueChanged<GiTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, GiTab.home, Icons.home_outlined, 'Accueil'),
              _item(context, GiTab.guests, Icons.group_outlined, 'Invités'),
              _centerPlus(p),
              _item(context, GiTab.invitations,
                  Icons.mail_outline_outlined, 'Invitations'),
              _item(context, GiTab.more, Icons.grid_view_outlined, 'Plus'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerPlus(GiPalette p) {
    return GestureDetector(
      onTap: () => onSelect(GiTab.add),
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.primary,
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, GiTab tab, IconData icon, String label) {
    final p = GiPalette.of(context);
    final active = current == tab;
    final color = active ? p.primaryBright : p.textSecondary;
    return InkWell(
      onTap: () => onSelect(tab),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

/// Bouton principal violet pleine largeur.
class GiPrimaryButton extends StatelessWidget {
  const GiPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: p.primary,
        borderRadius: BorderRadius.circular(GiRadius.button),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(GiRadius.button),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de réglages profil (icône + libellé [+ valeur] + chevron).
class GiSettingsTile extends StatelessWidget {
  const GiSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    final fg = destructive ? GiColors.danger : p.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border, width: 1))),
        child: Row(
          children: [
            Icon(icon, size: 21, color: destructive ? GiColors.danger : p.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: fg)),
            ),
            if (value != null)
              Text(value!,
                  style: TextStyle(fontSize: 12, color: p.textSecondary))
            else if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right, size: 22, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}