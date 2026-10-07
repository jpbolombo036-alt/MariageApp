import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

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
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName ?? 'Événement',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (venue != null && venue!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: p.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              venue!,
                              maxLines: 1,
                              style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.3),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (dateLabel != null && dateLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 15, color: p.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateLabel!,
                              maxLines: 1,
                              style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.3),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? p.successBg : p.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          Icon(Icons.circle, size: 8, color: AppColors.success),
                          const SizedBox(width: 8),
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
          Container(
            width: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary, p.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Icon(Icons.event_rounded, color: Colors.white.withValues(alpha: 0.9), size: 34),
          ),
        ],
      ),
    );
  }
}
