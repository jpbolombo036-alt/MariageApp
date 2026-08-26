import 'package:flutter/material.dart';

/// Builder de transition « stable ».
///
/// Renvoie directement l'enfant, sans fondu ni décalage (slide/parallaxe).
/// Cette transition neutre évite le rendu « paint avant layout » que le
/// framework Flutter peut déclencher pendant les transitions par défaut de
/// [MaterialPageRoute], à l'origine des assertions « RenderBox was not laid
/// out » et « Cannot hit test a render box that has never been laid out ».
class StablePageTransitionsBuilder extends PageTransitionsBuilder {
  const StablePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Applique des transitions de route stables (sans animation de glissement)
/// à l'ensemble des plateformes prises en charge.
///
/// À utiliser comme `builder:` de [MaterialApp] :
/// ```dart
/// MaterialApp(
///   builder: (context, child) => NavigatorWrapper(child: child!),
///   ...
/// )
/// ```
/// Le wrapper surcharge uniquement `pageTransitionsTheme` au-dessus du
/// Navigator géré par MaterialApp : toutes les [MaterialPageRoute]
/// (Navigator.push) utilisent alors la transition stable, contournant ainsi
/// l'assertion « RenderBox was not laid out » sur cet environnement.
class NavigatorWrapper extends StatelessWidget {
  const NavigatorWrapper({super.key, required this.child});

  final Widget child;

  static const PageTransitionsTheme _stableTheme = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: StablePageTransitionsBuilder(),
      TargetPlatform.fuchsia: StablePageTransitionsBuilder(),
      TargetPlatform.iOS: StablePageTransitionsBuilder(),
      TargetPlatform.linux: StablePageTransitionsBuilder(),
      TargetPlatform.macOS: StablePageTransitionsBuilder(),
      TargetPlatform.windows: StablePageTransitionsBuilder(),
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(pageTransitionsTheme: _stableTheme),
      child: child,
    );
  }
}