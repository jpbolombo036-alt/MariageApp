import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

/// Carte de présentation de l'événement en cours (espace AGENT_ACCUEIL).
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    this.eventName,
    this.venue,
    this.dateLabel,
    this.statusLabel,
    this.isActive = false,
  });

  final String? eventName;
  final String? venue;
  final String? dateLabel;
  final String? statusLabel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: p.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName ?? 'Événement',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (venue != null && venue!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: p.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue!,
                            maxLines: 1,
                            style: TextStyle(color: p.textSecondary, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (dateLabel != null && dateLabel!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: p.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? p.successBg : p.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          Icon(Icons.circle, size: 9, color: AppColors.success),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                          statusLabel ?? (isActive ? 'ÉVÉNEMENT EN COURS' : 'ÉVÉNEMENT'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? AppColors.success : p.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _Cover(palette: p),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.palette});

  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 56),
    );
  }
}