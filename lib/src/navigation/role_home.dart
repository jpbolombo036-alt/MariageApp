import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/agent_accueil/presentation/screens/agent_accueil_home_screen.dart';
import '../../features/gestionnaire_invites/screens/gestionnaire_home_screen.dart';
import '../../features/organisateur/presentation/screens/organisateur_home_screen.dart';
import '../auth/auth_providers.dart';
import '../home/home_page.dart';

/// Accueil après connexion, selon le rôle le plus élevé.
class RoleHome extends ConsumerWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(authControllerProvider).user?.roles ?? const <String>[];
    if (_has(roles, 'SUPER_ADMIN') || _has(roles, 'ORGANISATEUR')) {
      return const OrganisateurHomeScreen();
    }
    if (_has(roles, 'GESTIONNAIRE_INVITES')) {
      return const GestionnaireInvitesHomeScreen();
    }
    if (_has(roles, 'AGENT_ACCUEIL')) {
      return const AgentAccueilHomeScreen();
    }
    return const HomePage();
  }

  bool _has(List<String> roles, String role) => roles.any((item) => item == role);
}
