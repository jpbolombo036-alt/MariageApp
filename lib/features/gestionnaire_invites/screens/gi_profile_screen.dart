import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/gi_ui.dart';
import '../widgets/gi_nav.dart';

/// Écran « Mon profil » du rôle GESTIONNAIRE_INVITES.
class GiProfileScreen extends ConsumerStatefulWidget {
  const GiProfileScreen({super.key});

  @override
  ConsumerState<GiProfileScreen> createState() => _GiProfileScreenState();
}

class _GiProfileScreenState extends ConsumerState<GiProfileScreen> {
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content:
            const Text('Vous devrez vous reconnecter pour accéder à votre espace.'),
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
    // Le routeur global réagit à l'état d'authentification (retour login).
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final name = user == null
        ? '—'
        : '${user.firstName} ${user.lastName}'.trim();
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20, color: p.textPrimary)),
        title: Text('Mon profil', style: TextStyle(color: p.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF45219B),
                Color(0xFF6D45D8),
              ]),
              borderRadius: BorderRadius.circular(GiRadius.card),
            ),
            child: Row(children: [
              CircleAvatar(radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: .22),
                  child: Icon(Icons.person, size: 30, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (email.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.mail_outline, size: 13, color: Colors.white70),
                      SizedBox(width: 6),
                      Expanded(child: Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.white70))),
                    ]),
                  ],
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('GESTIONNAIRE_INVITES',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                            letterSpacing: .6, color: Colors.white)),
                  ),
                ])),
            ]),
          ),
          const SizedBox(height: 24),
          _section(context, p),
          const SizedBox(height: 20),
          _logoutTile(p),
        ]),
      ),
    );
  }

  Widget _logoutTile(GiPalette p) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(GiRadius.button),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: GiColors.dangerBg.withValues(alpha: p.isDark ? 0.12 : 1),
            borderRadius: BorderRadius.circular(GiRadius.button),
            border: Border.all(color: GiColors.danger.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(Icons.logout, size: 20, color: GiColors.danger),
            const SizedBox(width: 12),
            Text('Se déconnecter',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GiColors.danger)),
          ]),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, GiPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GiRadius.card),
        border: Border.all(color: p.border),
      ),
      child: Column(children: [
        GiSettingsTile(icon: Icons.person_outline, label: 'Informations personnelles', onTap: () {}),
        GiSettingsTile(icon: Icons.lock_outline, label: 'Changer le mot de passe', onTap: () {}),
        GiSettingsTile(icon: Icons.tune, label: 'Préférences', onTap: () {}),
        GiSettingsTile(icon: Icons.notifications_none_outlined, label: 'Notifications', onTap: () {}),
        GiSettingsTile(icon: Icons.language, label: 'Langue', value: 'Français', onTap: () {}),
      ]),
    );
  }
}