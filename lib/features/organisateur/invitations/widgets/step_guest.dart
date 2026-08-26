import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Indicateur horizontal d'étapes (Invité → Détails → Confirmation).
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.steps,
    required this.current,
  });

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: current > i ? InvColors.primary : p.border,
              ),
            ),
          _step(context, i, steps[i]),
        ],
      ],
    );
  }

  Widget _step(BuildContext context, int index, String label) {
    final active = current == index;
    final completed = current > index;
    final p = InvPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active || completed ? InvColors.primary : p.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active || completed ? InvColors.primary : p.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: InvType.badge(
                      active ? Colors.white : p.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: InvType.cardMuted(
            active ? InvColors.primary : p.textSecondary,
          ).copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Carte de l'invité sélectionné dans le formulaire de création.
class SelectedGuestCard extends StatelessWidget {
  const SelectedGuestCard({
    super.key,
    required this.name,
    this.email,
    this.phone,
    this.persons,
    this.category,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? persons;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InvSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.card),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: InvColors.primaryLight,
            child: Text(
              name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
              style: InvType.guestName(InvColors.primaryDark)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: InvType.guestName(p.textPrimary)),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(email!, style: InvType.cardMuted(p.textSecondary)),
                ],
                if (phone != null && phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone!, style: InvType.cardMuted(p.textSecondary)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (persons != null) _meta(context, Icons.people_outline, persons!),
                    if (category != null) _meta(context, Icons.label_outline, category!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    final p = InvPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: InvType.badge(p.textSecondary)),
        ],
      ),
    );
  }
}