import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';

/// En-tÃÂªte de section : titre ÃÂ  gauche + action ÃÂ« Voir tout ÃÂ» ÃÂ  droite.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'Voir tout >',
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.cardTitle(color: scheme.onSurface),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              seeAllLabel,
               style: AppTypography.small(
                 color: scheme.primary,
               ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Badge de statut (en cours / ÃÂ  venir / brouillon / confirmÃÂ© / ...).
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.color = OrganizerColors.success,
    this.background = OrganizerColors.successBg,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
         style: AppTypography.small(
           color: color,
         ).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Ãâ°tat vide ÃÂ©lÃÂ©gant.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle(color: scheme.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                 style: AppTypography.body(
                   color: scheme.onSurface.withValues(alpha: 0.6),
                 ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ãâ°tat d'erreur avec bouton ÃÂ« RÃÂ©essayer ÃÂ».
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Impossible de charger les donnÃÂ©es',
    this.message = 'VÃÂ©rifiez votre connexion puis rÃÂ©essayez.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle(),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
               style: AppTypography.body(
                 color: scheme.onSurface.withValues(alpha: 0.6),
               ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onRetry, child: const Text('RÃÂ©essayer')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ãâ°tat de chargement (skeleton simple).
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

