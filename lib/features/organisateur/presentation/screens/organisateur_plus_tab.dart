import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/admin/admin_page.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/theme/theme_controller.dart';
import '../../../../src/user/profile_edit_page.dart';
import '../../../../src/wedding/wedding_api.dart';
import 'change_password_screen.dart';
import 'create_user_screen.dart';

/// Onglet « Plus » de l'ORGANISATEUR : profil, équipe, préférences, déconnexion.
class OrganizerMoreTab extends ConsumerWidget {
  const OrganizerMoreTab({
    super.key,
    required this.weddings,
    required this.selectedWeddingId,
    required this.onSelectWedding,
  });

  final List<Wedding> weddings;
  final int? selectedWeddingId;
  final ValueChanged<int> onSelectWedding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final hasTeamPerm =
        auth.hasPermission(PermissionCodes.organizationManageMembers);
    final isSuperAdmin =
        (user?.roles ?? const <String>[]).any((role) => role == 'SUPER_ADMIN');
    final themeMode = ref.watch(themeModeProvider);
    final displayName =
        user == null ? '—' : '${user.firstName} ${user.lastName}'.trim();
    final email = user?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plus', style: AppTypography.display(color: scheme.onSurface)),
          const SizedBox(height: 16),
          if (weddings.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      () {
                        Wedding? selected;
                        try {
                          selected = weddings.firstWhere((w) => w.id == selectedWeddingId);
                        } catch (_) {
                          selected = weddings.isNotEmpty ? weddings.first : null;
                        }
                        return selected?.displayName.isNotEmpty == true ? selected!.displayName : 'Événement';
                      }(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  PopupMenuButton<int>(
                    icon: Icon(Icons.swap_vert_rounded, color: scheme.onSurfaceVariant, size: 20),
                    onSelected: onSelectWedding,
                    itemBuilder: (context) => [
                      for (final w in weddings)
                        PopupMenuItem(
                          value: w.id,
                          child: Text(
                            w.displayName.isNotEmpty ? w.displayName : 'Événement ${w.id}',
                            style: TextStyle(
                              color: w.id == selectedWeddingId ? scheme.primary : scheme.onSurface,
                              fontWeight: w.id == selectedWeddingId ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [
                    OrganizerColors.primaryDark,
                    OrganizerColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: .22),
                    child: Icon(Icons.person, size: 30, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      if (email.isNotEmpty)
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Gestion',
              style: AppTypography.sectionTitle(color: scheme.onSurface)),
          const SizedBox(height: 8),
          if (hasTeamPerm)
            _Tile(scheme,
                icon: Icons.group_add_outlined,
                label: 'Gérer l\u2019équipe',
                subtitle: 'Ajouter un membre',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                  );
                }),
          if (isSuperAdmin)
            _Tile(scheme,
                icon: Icons.admin_panel_settings_outlined,
                label: 'Administration',
                subtitle: 'Utilisateurs, rôles, organisations',
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminPage(),
                      ),
                    )),
          _Tile(scheme,
              icon: Icons.person_outline,
              label: 'Informations personnelles',
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditPage(),
                    ),
                  )),
          _Tile(scheme,
              icon: Icons.lock_outline,
              label: 'Changer le mot de passe',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()))),
          _Tile(scheme,
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              onTap: () {}),
          _Tile(scheme,
              icon: Icons.language,
              label: 'Langue',
              value: 'Français',
              onTap: () {}),
          _Tile(scheme,
              icon: Icons.dark_mode_outlined,
              label: 'Apparence',
              value: themeModeLabel(themeMode),
              onTap: () => showThemeModePicker(context, ref)),
          const SizedBox(height: 24),
          _LogoutTile(scheme),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.scheme,
      {required this.icon,
      required this.label,
      this.subtitle,
      this.value,
      this.onTap});

  final ColorScheme scheme;
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 21, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 14, color: scheme.onSurface)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (value != null)
              Text(value!,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
            else
              Icon(Icons.chevron_right, size: 22, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile(this.scheme);

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Se déconnecter ?'),
            content: const Text(
                'Vous devrez vous reconnecter pour accéder à votre espace.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Retour')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Déconnexion')),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        final ref = ProviderScope.containerOf(context);
        await ref.read(authControllerProvider.notifier).logout();
      },
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: OrganizerColors.dangerBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: OrganizerColors.danger),
            const SizedBox(width: 12),
            Text('Déconnexion',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OrganizerColors.danger)),
          ],
        ),
      ),
    );
  }
}
