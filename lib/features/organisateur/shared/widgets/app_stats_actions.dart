import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

/// Carte statistique compacte (nombre + libellé).
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.suffix,
  });

  final String value;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.subtle(scheme.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.stat(color: scheme.primary),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix!,
                   style: AppTypography.small(
                     color: scheme.outline,
                   ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
             style: AppTypography.small(
               color: scheme.onSurface.withValues(alpha: 0.6),
             ),
          ),
        ],
      ),
    );
  }
}

/// Action rapide (icône circulaire + libellés).
class AppQuickAction extends StatelessWidget {
  const AppQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: scheme.primary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
             style: AppTypography.small(
               color: scheme.onSurface,
             ).copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
             style: AppTypography.small(
               color: scheme.onSurface.withValues(alpha: 0.5),
             ).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
