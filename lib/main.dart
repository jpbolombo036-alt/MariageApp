import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/agent_accueil/presentation/screens/agent_accueil_home_screen.dart';
import 'features/gestionnaire_invites/screens/gestionnaire_home_screen.dart';
import 'features/organisateur/presentation/screens/organisateur_home_screen.dart';
import 'src/auth/auth_providers.dart';
import 'src/auth/login_page.dart';
import 'src/auth/splash_page.dart';
import 'src/home/home_page.dart';
import 'src/navigation/navigator_wrapper.dart';
import 'src/theme/app_theme.dart';

/// Fournit le thème clair/sombre global (défaut : clair).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

void main() {
  // Nécessaire pour flutter_secure_storage (MethodChannel) before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MariagePlusApp(),
    ),
  );
}

/// Racine de l'application MariagePlus.
class MariagePlusApp extends ConsumerWidget {
  const MariagePlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'MariagePlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // Stabilise les transitions de route (contourne « RenderBox was not
      // laid out » déclenché par les transitions par défaut de MaterialPageRoute).
      builder: (context, child) => NavigatorWrapper(child: child!),
      home: const _AuthRouter(),
    );
  }
}

/// Router d'authentification : Splash → Login/Register ↔ Esapces par rôle.
class _AuthRouter extends ConsumerWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.restored) {
      ref.read(authControllerProvider.notifier).kickRestore();
      return const SplashPage();
    }

    if (auth.isAuthenticated) {
      // Règle de redirection par rôle : chaque rôle a son espace dédié.
      final roles = auth.user?.roles ?? const <String>[];
      if (roles.any((r) => r == 'AGENT_ACCUEIL')) {
        return const AgentAccueilHomeScreen();
      }
      // L'ORGANISATEUR dispose d'un espace complet de gestion d'événements.
      if (roles.any((r) => r == 'ORGANISATEUR')) {
        return const OrganisateurHomeScreen();
      }
      // Le GESTIONNAIRE_INVITES gère invités, catégories, invitations, RSVP.
      if (roles.any((r) => r == 'GESTIONNAIRE_INVITES')) {
        return const GestionnaireInvitesHomeScreen();
      }
      return const HomePage();
    }

    return LoginPage(controller: ref.read(authControllerProvider.notifier));
  }
}