import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/auth/auth_providers.dart';
import 'src/auth/login_page.dart';
import 'src/home/home_page.dart';

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
class MariagePlusApp extends StatelessWidget {
  const MariagePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MariagePlus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AuthRouter(),
    );
  }
}

/// Router d'authentification : Splash → Login/Register ↔ Home.
class _AuthRouter extends ConsumerWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.restored) {
      ref.read(authControllerProvider.notifier).kickRestore();
      return const SizedBox.shrink();
    }

    if (auth.isAuthenticated) {
      return const HomePage();
    }

    return LoginPage(controller: ref.read(authControllerProvider.notifier));
  }
}