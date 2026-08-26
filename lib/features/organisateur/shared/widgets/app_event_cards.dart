import 'package:flutter/material.dart';

import '../../../../src/theme/app_theme.dart';
import 'app_states.dart' show AppStatusBadge;

/// Grande carte « événement en cours » (dashboard).
class AppCurrentEventCard extends StatelessWidget {
  const AppCurrentEventCard({
    super.key,
    required this.name,
    this.date,
    this.venue,
    this.onDetails,
  });

  final String name;
  final String? date;
  final String? venue;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.eventCard),
        gradient: const LinearGradient(
          colors: [OrganizerColors.primary, OrganizerColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Partie gauche : contenu
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ãâ°vÃÂ©nement en cours',
                    style: AppTypography.small(color: Colors.white70),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                     style: AppTypography.cardTitle(
                       color: Colors.white,
                     ).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 10),
                  if (date != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(date!, style: AppTypography.small(color: Colors.white70)),
                      ],
                    ),
                  ],
                  if (venue != null && venue!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(venue!, style: AppTypography.small(color: Colors.white70)),
                      ],
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: onDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: OrganizerColors.primaryDark,
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('Voir les dÃÂ©tails'),
                  ),
                ],
              ),
            ),
          ),
          // Partie droite : visuel reprÃÂ©sentatif
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black26],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Center(
                child: Text('✨', style: const TextStyle(fontSize: 48)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/// Carte d'un ÃÂ©vÃÂ©nement dans la liste.
class AppEventCard extends StatelessWidget {
  const AppEventCard({
    super.key,
    required this.name,
    this.date,
    this.venue,
    this.statusLabel,
    this.statusColor = OrganizerColors.success,
    this.statusBg = OrganizerColors.successBg,
    this.onTap,
    this.onMenu,
  });

  final String name;
  final String? date;
  final String? venue;
  final String? statusLabel;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.subtle(scheme.shadow),
          ),
          child: Row(
            children: [
              // Visuel ÃÂ  gauche
              Container(
                width: 104,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [OrganizerColors.primary, OrganizerColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Center(
                child: Text('✨', style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 14),
              // Contenu ÃÂ  droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                       style: AppTypography.subtitle(
                         color: scheme.onSurface,
                       ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (statusLabel != null)
                      AppStatusBadge(
                        label: statusLabel!,
                        color: statusColor,
                        background: statusBg,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      [
                         if (date != null) date,
                         if (venue?.isNotEmpty ?? false) venue!,
                      ].join(' ÃÂ· '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                       style: AppTypography.small(
                         color: scheme.onSurface.withValues(alpha: 0.6),
                       ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

