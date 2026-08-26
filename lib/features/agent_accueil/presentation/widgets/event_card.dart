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
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Partie gauche : contenu.
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  const SizedBox(height: 8),
                  Text(
                    eventName ?? 'Événement',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.agentNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (venue != null && venue!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.agentTextSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue!,
                            style: const TextStyle(color: AppColors.agentTextSecondary, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (dateLabel != null && dateLabel!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.agentTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel!,
                          style: const TextStyle(color: AppColors.agentTextSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.successBg : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          const Icon(Icons.circle, size: 9, color: AppColors.success),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          statusLabel ?? (isActive ? 'ÉVÉNEMENT EN COURS' : 'ÉVÉNEMENT'),
                          style: TextStyle(
                            color: isActive ? AppColors.success : AppColors.agentTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Partie droite : visuel décoratif (ou image couverture).
          Expanded(
            flex: 2,
            child: _Cover(),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.agentNavy, AppColors.agentGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white54, size: 56),
    );
  }
}