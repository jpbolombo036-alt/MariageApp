import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_api.dart';
import 'dashboard_providers.dart';

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
      final data = await ref.read(dashboardApiProvider).getForWedding(widget.weddingId);
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
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final dash = _dashboard;
    if (dash == null) {
      return const Center(child: Text('Aucune donnée'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverview(dash),
          const SizedBox(height: 24),
          Text('Par catégorie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (dash.categories.isEmpty)
            const Text('Aucune catégorie')
          else
            ...dash.categories.map((c) => _CategoryTile(category: c)),
        ],
      ),
    );
  }

  Widget _buildOverview(Dashboard dash) {
    final overview = _Overview(
      guests: dash.guests,
      invitations: dash.invitations,
      attendance: dash.attendance,
      tables: dash.tables,
    );
    return overview;
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.guests,
    required this.invitations,
    required this.attendance,
    required this.tables,
  });

  final GuestStats guests;
  final InvitationStats invitations;
  final AttendanceStats attendance;
  final TableStats tables;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vue d\'ensemble', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(label: 'Invités', value: '${guests.total}', icon: Icons.group_outlined),
                _StatChip(label: 'Confirmés', value: '${invitations.accepted}', icon: Icons.check_circle_outlined),
                _StatChip(label: 'Refusés', value: '${invitations.declined}', icon: Icons.cancel_outlined),
                _StatChip(label: 'En attente', value: '${invitations.pending}', icon: Icons.schedule_outlined),
                _StatChip(label: 'Présents', value: '${attendance.checkedIn}', icon: Icons.verified_outlined),
                _StatChip(label: 'Tables', value: '${tables.total}', icon: Icons.table_restaurant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CategoryStats category;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Invités : ${category.totalGuests}'),
            Text('Confirmés : ${category.accepted}'),
            Text('Refusés : ${category.declined}'),
            Text('En attente : ${category.pending}'),
          ],
        ),
      ),
    );
  }
}
