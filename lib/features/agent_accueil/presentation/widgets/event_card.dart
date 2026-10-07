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
        boxShadow: p.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eventName ?? 'Événement',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 7, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'EN COURS',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (venue != null && venue!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                        padding: const EdgeInsets.only(bottom: 8),
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
                    const SizedBox(height: 18),
                    Container(
                      height: 3,
                      width: 36,
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [p.primary, p.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.event_rounded, color: Colors.white.withValues(alpha: 0.92), size: 36),
            ),
          ],
        ),
      ),
    );
  }
}
