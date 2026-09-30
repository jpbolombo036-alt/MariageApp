import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'wedding_api.dart';
import 'wedding_create_page.dart';
import 'wedding_detail_page.dart';
import 'wedding_providers.dart';

class WeddingListPage extends ConsumerStatefulWidget {
  const WeddingListPage({super.key});

  @override
  ConsumerState<WeddingListPage> createState() => _WeddingListPageState();
}

class _WeddingListPageState extends ConsumerState<WeddingListPage> {
  bool _loading = true;
  String? _error;
  List<Wedding> _items = const [];

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
      final items = await ref.read(weddingApiProvider).list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les événements';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.weddingCreate);

    return Scaffold(
      appBar: AppBar(title: const Text('Événements')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<Wedding>(
                  MaterialPageRoute(builder: (_) => const WeddingCreatePage()),
                );
                if (created != null && mounted) {
                  _load();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canCreate),
    );
  }

  Widget _buildBody(bool canCreate) {
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
    if (_items.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('Aucun événement pour le moment'),
            if (canCreate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final created = await Navigator.of(context).push<Wedding>(
                    MaterialPageRoute(builder: (_) => const WeddingCreatePage()),
                  );
                  if (created != null && mounted) {
                    _load();
                  }
                },
                child: const Text('Créer un événement'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final w = _items[index];
          final typeLabel = _typeLabel(w.eventTypeEnum);
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(typeLabel.icon)),
              title: Text(w.displayName),
              subtitle: Text('${typeLabel.label} · ${_statusLabel(w.status)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WeddingDetailPage(weddingId: w.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ({IconData icon, String label}) _typeLabel(EventType? type) {
    return switch (type) {
      EventType.collation => (icon: Icons.celebration, label: 'Collation'),
      EventType.anniversary => (icon: Icons.cake, label: 'Anniversaire'),
      EventType.baptism => (icon: Icons.church, label: 'Baptême'),
      EventType.graduation => (icon: Icons.school, label: 'Graduation'),
      EventType.other => (icon: Icons.event, label: 'Autre'),
      _ => (icon: Icons.favorite, label: 'Mariage'),
    };
  }

  String _statusLabel(String status) => switch (status) {
        'PUBLISHED' => 'Publié',
        'ACTIVE' => 'Actif',
        'COMPLETED' => 'Terminé',
        'ARCHIVED' => 'Archivé',
        'CANCELLED' => 'Annulé',
        _ => 'Brouillon',
      };
}
