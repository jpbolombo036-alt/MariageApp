import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Barre de recherche d'invités.
class InvitationSearchBar extends StatelessWidget {
  const InvitationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.hint = 'Rechercher un invité...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: InvType.cardBody(p.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: InvType.cardMuted(p.textTertiary),
                prefixIcon: Icon(Icons.search, size: 20, color: p.textTertiary),
                filled: true,
                fillColor: p.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InvRadius.field),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InvRadius.field),
                  borderSide: const BorderSide(
                      color: InvColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(InvRadius.field),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(InvRadius.field),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(InvRadius.field),
                border: Border.all(color: p.border),
              ),
              child: Icon(Icons.tune, size: 20, color: p.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Puce de filtre horizontale sélectionnable.
class InvitationFilterChips extends StatelessWidget {
  const InvitationFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = options[i];
          final active = o == selected;
          return GestureDetector(
            onTap: () => onSelected(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? InvColors.primary
                    : p.surfaceSecondary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? InvColors.primary : p.border,
                ),
              ),
              child: Text(
                o,
                style: InvType.badge(
                  active ? Colors.white : p.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}