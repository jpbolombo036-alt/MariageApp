import 'package:flutter/material.dart';
import '../../../../src/theme/app_theme.dart';

class OrganizerHomeHeader extends StatelessWidget {
  const OrganizerHomeHeader({
    super.key,
    required this.userName,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                'M',
                style: AppTypography.cardTitle(color: Colors.white)
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MariagePlus',
                style: AppTypography.cardTitle(color: scheme.onSurface)
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Organisateur',
                style: AppTypography.small(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_none_outlined, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: AppTypography.body(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveEventCard extends StatelessWidget {
  const ActiveEventCard({
    super.key,
    required this.eventName,
    required this.status,
    required this.names,
    this.onTap,
  });

  final String eventName;
  final String status;
  final String names;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final cardBg = isDark
        ? OrganizerColors.darkSurfaceSecondary
        : OrganizerColors.lightSurfaceViolet;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.small(
                        color: scheme.onPrimaryContainer,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              eventName,
              style: AppTypography.display(color: scheme.onSurface)
                  .copyWith(fontSize: 20),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (names.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      names,
                      style: AppTypography.small(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Voir le tableau de bord',
                  style: AppTypography.small(color: scheme.primary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: scheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: scheme.primary),
          ),
          const SizedBox(height: 14),
          Text(value, style: AppTypography.stat(color: scheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.small(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class EventPreviewCard extends StatelessWidget {
  const EventPreviewCard({
    super.key,
    required this.name,
    required this.names,
    required this.guestsCount,
    this.onTap,
  });

  final String name;
  final String names;
  final int guestsCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.1),
                    scheme.primaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text('✨', style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ÉVÉNEMENT',
                style: AppTypography.small(
                  color: scheme.onPrimaryContainer,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTypography.cardTitle(color: scheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (names.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      names,
                      style: AppTypography.small(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (guestsCount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '$guestsCount invités',
                    style: AppTypography.small(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrganizerHomeSkeleton extends StatelessWidget {
  const OrganizerHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                _Shimmer(width: 40, height: 40, baseColor: baseColor, highlightColor: highlightColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Shimmer(width: 120, height: 18, baseColor: baseColor, highlightColor: highlightColor),
                    const SizedBox(height: 4),
                    _Shimmer(width: 80, height: 12, baseColor: baseColor, highlightColor: highlightColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 100, height: 14, baseColor: baseColor, highlightColor: highlightColor),
                const SizedBox(height: 8),
                _Shimmer(width: 200, height: 26, baseColor: baseColor, highlightColor: highlightColor),
                const SizedBox(height: 6),
                _Shimmer(width: 280, height: 14, baseColor: baseColor, highlightColor: highlightColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _Shimmer(
              width: double.infinity,
              height: 180,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Shimmer(width: 100, height: 18, baseColor: baseColor, highlightColor: highlightColor),
                _Shimmer(width: 60, height: 14, baseColor: baseColor, highlightColor: highlightColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _Shimmer(width: double.infinity, height: 120, baseColor: baseColor, highlightColor: highlightColor)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _Shimmer(width: double.infinity, height: 120, baseColor: baseColor, highlightColor: highlightColor)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _Shimmer(width: double.infinity, height: 120, baseColor: baseColor, highlightColor: highlightColor)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _Shimmer(width: double.infinity, height: 120, baseColor: baseColor, highlightColor: highlightColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Shimmer(width: 120, height: 18, baseColor: baseColor, highlightColor: highlightColor),
                _Shimmer(width: 60, height: 14, baseColor: baseColor, highlightColor: highlightColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _Shimmer(
              width: 260,
              height: 220,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
  });

  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        final shimmer = (value * 2) % 2 - 1;
        final opacity = 0.3 + (shimmer.abs() * 0.4);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        );
      },
    );
  }
}

class OrganizerHomeEmptyState extends StatelessWidget {
  const OrganizerHomeEmptyState({super.key, this.onAction});

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
            Icon(Icons.event_note_outlined, size: 64, color: scheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Créez votre premier événement',
              style: AppTypography.cardTitle(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à organiser vos invités, invitations et présences en quelques étapes.',
              style: AppTypography.body(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (onAction != null)
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Créer un événement'),
              ),
          ],
        ),
      ),
    );
  }
}

class OrganizerHomeErrorState extends StatelessWidget {
  const OrganizerHomeErrorState({super.key, this.onRetry});

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
            Icon(Icons.cloud_off_outlined, size: 64, color: scheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger vos événements',
              style: AppTypography.cardTitle(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion et réessayez.',
              style: AppTypography.body(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (onRetry != null)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }
}
