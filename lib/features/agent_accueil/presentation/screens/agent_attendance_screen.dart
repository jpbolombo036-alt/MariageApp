import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/theme/app_colors.dart';
import '../widgets/attendance_stat_card.dart';

/// Écran « Présences » de l'espace AGENT_ACCUEIL (onglet Présences).
class AgentAttendanceScreen extends ConsumerStatefulWidget {
  const AgentAttendanceScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<AgentAttendanceScreen> createState() =>
      _AgentAttendanceScreenState();
}

class _AgentAttendanceScreenState extends ConsumerState<AgentAttendanceScreen> {
  bool _loading = true;
  String? _error;
  Dashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dash =
          await ref.read(dashboardApiProvider).getForWedding(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _dashboard = dash;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les présences';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final a = _dashboard!.attendance;
    final cats = _dashboard!.categories;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Présences',
            style: const TextStyle(
              color: AppColors.agentNavy,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Suivi des arrivées de l'événement",
            style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AttendanceStatCard(
                icon: Icons.group_outlined,
                value: '${a.expected}',
                label: 'Invités attendus',
              ),
              const SizedBox(width: 14),
              AttendanceStatCard(
                icon: Icons.check_circle_outline,
                value: '${a.checkedIn}',
                label: 'Invités présents',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProgressCard(attendance: a),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 20),
            _CategoriesCard(categories: cats),
          ],
        ],
      ),
    );
  }
}
/// Carte d'avancement : restants + taux + barre de progression.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.attendance});

  final AttendanceStats attendance;

  @override
  Widget build(BuildContext context) {
    final rate = attendance.checkInRate.clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avancement de la soirée',
                style: TextStyle(
                  color: AppColors.agentNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(rate * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.agentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: attendance.expected == 0 ? 0 : rate,
              minHeight: 10,
              backgroundColor: AppColors.lightBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.agentGold),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(Icons.hourglass_empty, 'Restants', '${attendance.remaining}'),
              const SizedBox(width: 24),
              _miniStat(
                Icons.verified_user_outlined,
                'Taux',
                '${(rate * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.agentNavy),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.agentNavy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.agentTextSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
/// Répartition attendus / présents par catégorie d'invités.
class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.categories});

  final List<CategoryStats> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition par catégorie',
            style: TextStyle(
              color: AppColors.agentNavy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Basé sur les RSVP confirmés',
            style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (final c in categories) _categoryRow(c),
        ],
      ),
    );
  }

  Widget _categoryRow(CategoryStats cat) {
    final expected = cat.expectedAttendees;
    final accepted = cat.accepted;
    final rate = expected == 0 ? 0.0 : (accepted / expected).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cat.name.isEmpty ? 'Sans catégorie' : cat.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.agentNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$accepted / $expected',
                style: const TextStyle(
                  color: AppColors.agentTextSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue d'erreur avec bouton de reprise.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.agentNavy, fontSize: 15),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}