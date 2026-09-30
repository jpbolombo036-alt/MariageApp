import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Bloc branding centré : logo, nom "EventiaEasy", slogan.
class AuthBranding extends StatelessWidget {
  const AuthBranding({super.key, this.logoHeight = 78});

  /// Hauteur du logo (ou du placeholder) en dp.
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? OrganizerColors.darkText : AppColors.primaryNavy;
    final subtitleColor =
        dark ? OrganizerColors.darkSecondary : AppColors.textSecondary;
    final fontSize = MediaQuery.sizeOf(context).width < 340 ? 34.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _logo(dark),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.05,
            ),
            children: [
              TextSpan(text: 'Eventia', style: TextStyle(color: titleColor)),
              const TextSpan(
                text: 'Easy',
                style: TextStyle(color: OrganizerColors.primary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Invitations, accueil et suivi, au même endroit.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
            letterSpacing: 0.1,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _logo(bool dark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: dark ? OrganizerColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark ? OrganizerColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/logo.png',
          width: logoHeight,
          height: logoHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SizedBox(
            width: logoHeight,
            height: logoHeight,
            child: const FloralLogoFallback(),
          ),
        ),
      ),
    );
  }
}

/// Placeholder affiché uniquement si `assets/logo.png` ne peut pas être chargé
/// (voir le `errorBuilder` de `Image.asset` dans [AuthBranding]).
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
          border: Border.all(color: OrganizerColors.primary.withValues(alpha: 0.45), width: 1.4),
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
          color: OrganizerColors.primary,
          size: 26,
        ),
      ),
    );
  }
}