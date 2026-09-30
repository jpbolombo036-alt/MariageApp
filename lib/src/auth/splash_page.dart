import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Écran de lancement : logo et marque, clair ou sombre selon le thème.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background =
        dark ? OrganizerColors.darkBackground : OrganizerColors.lightBackground;
    final titleColor =
        dark ? OrganizerColors.darkText : AppColors.primaryNavy;

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Eventia', style: TextStyle(color: titleColor)),
                  const TextSpan(
                    text: 'Easy',
                    style: TextStyle(color: OrganizerColors.primary),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: OrganizerColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
