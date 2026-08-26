import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Sélecteur de l'événement courant (carte horizontale).
class EventSelectorCard extends StatelessWidget {
  const EventSelectorCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnailImage,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? thumbnailImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InvRadius.field),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(InvRadius.field),
            border: Border.all(color: p.border),
            boxShadow: p.cardShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbnailImage != null && thumbnailImage!.isNotEmpty
                    ? Image.network(
                        thumbnailImage!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InvType.cardBody(p.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InvType.cardMuted(p.textSecondary)
                            .copyWith(fontSize: 10, letterSpacing: 0.4),
                      ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, size: 24, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: InvColors.primaryLight,
      child: const Icon(
        Icons.auto_awesome,
        size: 24,
        color: InvColors.primary,
      ),
    );
  }
}