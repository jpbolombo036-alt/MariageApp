import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Séparateur discret « ——— OU ——— ».
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        const SizedBox(width: 16),
        Text(
          'OU',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

/// Footer discret : © 2026 MariagePlus + version.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, this.year = '2026', this.version = '1.0.0'});

  final String year;
  final String version;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('© $year MariagePlus. Tous droits réservés.', style: style, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Version $version', style: style.copyWith(fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }
}