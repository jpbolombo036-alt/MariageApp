import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/auth/auth_providers.dart';
import 'src/auth/login_page.dart';
import 'src/auth/splash_page.dart';
import 'src/checkin/checkin_public_page.dart';
import 'src/navigation/role_home.dart';
import 'src/navigation/rsvp_link.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: EventiaEasyApp(),
    ),
  );
}

class EventiaEasyApp extends ConsumerStatefulWidget {
  const EventiaEasyApp({super.key});

  @override
  ConsumerState<EventiaEasyApp> createState() => _EventiaEasyAppState();
}

class _EventiaEasyAppState extends ConsumerState<EventiaEasyApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRsvp(WidgetsBinding.instance.platformDispatcher.defaultRouteName);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    return Future.value(_openRsvp(routeInformation.uri.toString()));
  }

  bool _openRsvp(String raw) {
    final token = parseRsvpToken(raw);
    final navigator = _navigatorKey.currentState;
    if (token == null || navigator == null) return false;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PublicRsvpPage(initialToken: token),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'EventiaEasy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _AuthRouter(),
    );
  }
}

class _AuthRouter extends ConsumerStatefulWidget {
  const _AuthRouter();

  @override
  ConsumerState<_AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends ConsumerState<_AuthRouter> {
  var _holdSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _holdSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.restored) {
      ref.read(authControllerProvider.notifier).kickRestore();
    }

    if (!auth.restored || _holdSplash) {
      return const SplashPage();
    }

    if (auth.isAuthenticated) {
      return const RoleHome();
    }

    return LoginPage(controller: ref.read(authControllerProvider.notifier));
  }
}
