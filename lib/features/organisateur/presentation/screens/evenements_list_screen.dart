import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/app_event_cards.dart';
import '../../shared/widgets/app_states.dart';
import 'evenement_create_screen.dart';
import 'evenement_detail_screen.dart';

/// Liste des Ã?Â©vÃ?Â©nements (ORGANISATEUR).
class EvenementsListScreen extends ConsumerStatefulWidget {
  const EvenementsListScreen({super.key});

  @override
  ConsumerState<EvenementsListScreen> createState() =>
      _EvenementsListScreenState();
}

class _EvenementsListScreenState extends ConsumerState<EvenementsListScreen> {
  bool _loading = true;
  String? _error;
  List<Wedding> _events = const [];

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
      final items = await ref.read(weddingApiProvider).list(size: 25);
      if (!mounted) return;
      setState(() {
        _events = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les Ã?Â©vÃ?Â©nements';
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EvenementCreateScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Ã?Â©vÃ?Â©nements',
          style: AppTypography.display(color: scheme.onSurface),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: OrganizerColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvel Ã?Â©vÃ?Â©nement',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoadingState();
    if (_error != null) return AppErrorState(onRetry: _load);
    if (_events.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_note,
        title: 'Aucun Ã?Â©vÃ?Â©nement pour le moment',
        message: 'CrÃ?Â©ez votre premier Ã?Â©vÃ?Â©nement pour commencer.',
        actionLabel: 'CrÃ?Â©er un Ã?Â©vÃ?Â©nement',
        onAction: _create,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _events.length,
        separatorBuilder: (_, i) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final e = _events[index];
          return AppEventCard(
            name: e.displayName,
            date: _formatLabel(e),
            venue: 'Organisation #${e.organizationId}',
            statusLabel: e.status,
            statusColor: _statusColor(e.status),
            statusBg: _statusBg(e.status),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EvenementDetailScreen(weddingId: e.id),
              ),
            ),
            onMenu: () => _showMenu(e),
          );
        },
      ),
    );
  }

  String _formatLabel(Wedding e) {
    final parts = <String>[
      e.groomFirstName.isNotEmpty ? e.groomFirstName : 'Ã?â?°vÃ?Â©nement',
      if (e.brideFirstName.isNotEmpty) e.brideFirstName,
    ];
    return parts.join(' & ');
  }

  Color _statusColor(String status) => switch (status) {
    'PUBLISHED' || 'ACTIVE' => OrganizerColors.success,
    'DRAFT' => OrganizerColors.muted,
    _ => OrganizerColors.warning,
  };

  Color _statusBg(String status) => switch (status) {
    'PUBLISHED' || 'ACTIVE' => OrganizerColors.successBg,
    'DRAFT' => OrganizerColors.mutedBg,
    _ => OrganizerColors.warningBg,
  };

  void _showMenu(Wedding e) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Voir'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EvenementDetailScreen(weddingId: e.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modification bientÃ?Â´t disponible'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Changer le statut'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
