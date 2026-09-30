import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Décorations florales discrètes en arrière-plan (Stack).
///
/// Implémenté avec des icônes Material : le projet ne fournit aujourd'hui
/// qu'un seul asset image (`assets/logo.png`, déclaré dans pubspec.yaml).
/// Si des visuels floraux sont ajoutés plus tard, les déclarer dans pubspec
/// puis remplacer les icônes par `Image.asset(...)` (opacity ≈ 0.3).
class FloralDecorations extends StatelessWidget {
  const FloralDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Coin supérieur gauche
        Positioned(
          top: -18,
          left: -18,
          child: Opacity(
            opacity: 0.30,
            child: Icon(
              Icons.local_florist,
              size: 150,
              color: AppColors.gold.withValues(alpha: 0.9),
            ),
          ),
        ),
        // Coin inférieur droit
        Positioned(
          bottom: -24,
          right: -20,
          child: Opacity(
            opacity: 0.28,
            child: Icon(
              Icons.local_florist,
              size: 170,
              color: AppColors.gold.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}