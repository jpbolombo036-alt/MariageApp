import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

/// Champ de saisie rÃÂ©utilisable (style global organisateur).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffix,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.small(
            color: scheme.onSurface,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          validator: validator,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Champ de recherche.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Rechercher...',
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTypography.body(color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(Icons.search, color: scheme.onSurface.withValues(alpha: 0.5)),
              suffixIcon: onFilterTap != null
                  ? IconButton(
                      icon: Icon(Icons.tune, color: scheme.onSurface.withValues(alpha: 0.6)),
                      onPressed: onFilterTap,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
