import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_models.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_theme.dart';
import 'change_password_screen.dart';
import 'create_user_screen.dart';

/// Onglet « Plus » de l'ORGANISATEUR : profil, équipe, préférences, déconnexion.
class OrganizerMoreTab extends ConsumerStatefulWidget {
  const OrganizerMoreTab({super.key});

  @override
  ConsumerState<OrganizerMoreTab> createState() => _OrganizerMoreTabState();
}

class _OrganizerMoreTabState extends ConsumerState<OrganizerMoreTab> {
  Future<void> _logout() async {
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
    if (ok != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  void _openCreateUser() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateUserScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final hasTeamPerm =
        auth.hasPermission(PermissionCodes.organizationManageMembers);
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4520A5), Color(0xFF6C3BD2)],
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
            _tile(scheme,
                icon: Icons.group_add_outlined,
                label: 'Gérer l\u2019équipe',
                subtitle: 'Ajouter un membre',
                onTap: _openCreateUser),
          _tile(scheme,
              icon: Icons.person_outline,
              label: 'Informations personnelles',
              onTap: () {}),
          _tile(scheme,
              icon: Icons.lock_outline,
              label: 'Changer le mot de passe',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()))),
          _tile(scheme,
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              onTap: () {}),
          _tile(scheme,
              icon: Icons.language,
              label: 'Langue',
              value: 'Français',
              onTap: () {}),
          const SizedBox(height: 24),
          _logoutTile(scheme),
        ],
      ),
    );
  }

  Widget _tile(ColorScheme scheme,
      {required IconData icon,
      required String label,
      String? subtitle,
      String? value,
      VoidCallback? onTap}) {
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
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (value != null)
              Text(value,
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

  Widget _logoutTile(ColorScheme scheme) {
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3E3).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: const Color(0xFFDC2626)),
            const SizedBox(width: 12),
            Text('Déconnexion',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626))),
          ],
        ),
      ),
    );
  }
}