import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Bloc branding centré : logo, nom "MariagePlus", slogan.
class AuthBranding extends StatelessWidget {
  const AuthBranding({super.key, this.logoHeight = 78});

  /// Hauteur du logo (ou du placeholder) en dp.
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    // Réduction du titre sur très petits écrans.
    final fontSize = MediaQuery.sizeOf(context).width < 340 ? 38.0 : 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo : utilise l'asset officiel s'il existe, sinon un cercle décoratif.
        _logo(),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Mariage', style: TextStyle(color: AppColors.primaryNavy)),
              TextSpan(text: 'Plus', style: TextStyle(color: AppColors.gold)),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Organisez le plus beau jour de votre vie',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _logo() {
    return SizedBox(
      height: logoHeight,
      // BoxFit.contain pour ne jamais déformer l'asset logo s'il est fourni.
      child: const FloralLogoFallback(),
    );
  }
}

/// Placeholder de logo (cercles fleur doré) tant que l'asset officiel
/// `assets/images/logo.png` n'est pas présent. Remplacer par `Image.asset`.
class FloralLogoFallback extends StatelessWidget {
  const FloralLogoFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.4),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: AppColors.gold,
          size: 26,
        ),
      ),
    );
  }
}