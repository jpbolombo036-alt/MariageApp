import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_colors.dart';
import '../../../../src/theme/app_theme.dart';

/// Écran « Mon profil » de l'espace AGENT_ACCUEIL (onglet Profil).
class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content:
            const Text('Vous devrez vous reconnecter pour accéder à votre espace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Le routeur global réagit à l'état d'authentification (retour au login).
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final fullName =
        user == null ? '—' : '${user.firstName} ${user.lastName}'.trim();
    final email = user?.email ?? '';
    final initials = (user == null || user.firstName.isEmpty)
        ? 'A'
        : user.firstName[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(
            initials: initials,
            name: fullName,
            email: email,
            role: 'AGENT_ACCUEIL',
          ),
          const SizedBox(height: 24),
          _SettingsSection(onLogout: () => _confirmLogout(context, ref)),
        ],
      ),
    );
  }
}
/// Carte d'en-tête : avatar + nom + e-mail + badge de rôle.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
  });

  final String initials;
  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.agentNavy, Color(0xFF2E3D5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.agentGold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// Groupe de réglages (informations, sécurité, préférences, déconnexion).
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Informations personnelles',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Changer le mot de passe',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.tune,
            label: 'Préférences',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_none_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.language,
            label: 'Langue',
            value: 'Français',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Se déconnecter',
            isDestructive: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
/// Ligne de réglage de l'espace agent.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.isDestructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.agentNavy;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: AppColors.lightBorder.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? AppColors.danger : AppColors.agentNavy,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.agentTextSecondary,
                ),
              ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.agentTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}