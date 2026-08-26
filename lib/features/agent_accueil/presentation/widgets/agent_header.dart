import 'package:flutter/material.dart';

import '../../../../src/theme/app_colors.dart';

/// En-tête de l'espace AGENT_ACCUEIL : salutation + avatar + notification.
class AgentHeader extends StatelessWidget {
  const AgentHeader({
    super.key,
    required this.firstName,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onLogout,
  });

  final String firstName;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $firstName 👋',
                  style: const TextStyle(
                    color: AppColors.agentNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Agent d\u2019accueil',
                  style: TextStyle(
                    color: AppColors.agentTextSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotificationsTap,
            icon: const Icon(Icons.notifications_none, color: AppColors.agentNavy, size: 26),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.agentNavy,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Indicateur "actif" (vert) en bas à droite de l'avatar.
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}