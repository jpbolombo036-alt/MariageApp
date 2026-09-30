import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
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
  List<CheckInPresence> _present = const [];
  List<CheckInSearchHit> _hits = const [];
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.weddingId == 0) {
      setState(() {
        _loading = false;
        _error = 'Aucun événement assigné';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dash =
          await ref.read(dashboardApiProvider).getForWedding(widget.weddingId);
      final present =
          await ref.read(checkInApiProvider).listPresent(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _dashboard = dash;
        _present = present;
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

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty || widget.weddingId == 0) {
      setState(() => _hits = const []);
      return;
    }
    try {
      final hits = await ref.read(checkInApiProvider).searchGuests(widget.weddingId, q);
      if (!mounted) return;
      setState(() => _hits = hits);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recherche impossible')),
      );
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
    final p = AgentPalette.of(context);
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
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Suivi des arrivées de l'événement",
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _query,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un invité',
              prefixIcon: Icon(Icons.search, color: p.textSecondary),
              border: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: p.primary)),
            ),
            onSubmitted: _search,
          ),
          if (_hits.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final hit in _hits)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(hit.guestName, style: TextStyle(color: p.textPrimary)),
                subtitle: Text(
                  hit.canCheckIn
                      ? 'Peut entrer · ${hit.remainingAttendees} restant(s)'
                      : 'Entrée non disponible',
                  style: TextStyle(color: p.textSecondary),
                ),
              ),
          ],
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
          _ProgressCard(attendance: a, palette: p),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 20),
            _CategoriesCard(categories: cats, palette: p),
          ],
          if (_present.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Déjà présents',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final person in _present)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(person.guestName, style: TextStyle(color: p.textPrimary)),
                subtitle: Text(
                  [
                    '${person.numberOfAttendees} personne(s)',
                    if (person.tableName != null) person.tableName!,
                    if (person.drinkChoice != null) person.drinkChoice!,
                  ].join(' · '),
                  style: TextStyle(color: p.textSecondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
/// Carte d'avancement : restants + taux + barre de progression.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.attendance, required this.palette});

  final AttendanceStats attendance;
  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    final rate = attendance.checkInRate.clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avancement de la soirée',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(rate * 100).round()}%',
                style: TextStyle(
                  color: palette.goldBright,
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
              backgroundColor: palette.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(palette.goldBright),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(Icons.hourglass_empty, 'Restants', '${attendance.remaining}', palette),
              const SizedBox(width: 24),
              _miniStat(
                Icons.verified_user_outlined,
                'Taux',
                '${(rate * 100).round()}%',
                palette,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, AgentPalette p) {
    return Row(
      children: [
        Icon(icon, size: 18, color: p.textPrimary),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
/// Répartition attendus / présents par catégorie d'invités.
class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.categories, required this.palette});

  final List<CategoryStats> categories;
  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par catégorie',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Basé sur les RSVP confirmés',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
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
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$accepted / $expected',
                style: TextStyle(
                  color: palette.textSecondary,
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
              backgroundColor: palette.border,
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
    final p = AgentPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: p.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textPrimary, fontSize: 15),
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