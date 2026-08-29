import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_api.dart';
import 'dashboard_providers.dart';

/// Écran dashboard d'un événement (Wedding) : agrégats backend.
/// Charge `GET /api/events/{id}/dashboard` au montage + RefreshIndicator.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, required this.weddingId, required this.weddingName});

  final int weddingId;
  final String weddingName;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
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
      final api = ref.read(dashboardApiProvider);
      final data = await api.getForWedding(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le tableau de bord';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.weddingName),
      ),
      body: _buildBody(widget.weddingId),
    );
  }

  Widget _buildBody(int weddingId) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final d = _dashboard;
    if (d == null) return const Text('Aucune donnée');
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statCard(
              context: context,
              label: 'Invités',
              value: '${d.guests.total}',
              detail: '${d.guests.unassigned} non affectés',
            ),
            _statCard(
              context: context,
              label: 'Invitations',
              value: '${d.invitations.total}',
              detail:
                  '${d.invitations.accepted} acceptées · ${d.invitations.declined} refusées · '
                  '${d.invitations.pending} en attente',
            ),
            _statCard(
              context: context,
              label: 'Présence attendue',
              value: '${d.attendance.expected}',
              detail:
                  '${d.attendance.checkedIn} enregistrés · ${d.attendance.remaining} restants',
            ),
            _statCard(
              context: context,
              label: 'Tables',
              value: '${d.tables.total}',
              detail:
                  '${d.tables.assignedGuests} affectés · capacité ${d.tables.capacity}'
                  ' · restants ${d.tables.remainingCapacity}',
            ),
            const SizedBox(height: 16),
            Text(
              'Taux de réponse : ${_formatRate(d.invitations.responseRate)} %',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Taux de check-in : ${_formatRate(d.attendance.checkInRate)} %',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String label,
    required String value,
    required String detail,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(detail),
          ],
        ),
      ),
    );
  }

  String _formatRate(double value) {
    final formatted = value.toStringAsFixed(2);
    return formatted.replaceAll('.', ',');
  }
}