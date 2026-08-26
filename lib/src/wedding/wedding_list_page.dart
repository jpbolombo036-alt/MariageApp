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
  List<Wedding> _weddings = const [];

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
      final api = ref.read(weddingApiProvider);
      final items = await api.list();
      if (!mounted) return;
      setState(() {
        _weddings = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les événements';
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<Wedding>(
      MaterialPageRoute(builder: (_) => const WeddingCreatePage()),
    );
    if (created != null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.weddingCreate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_weddings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aucun événement pour le moment'),
            const SizedBox(height: 12),
            if (canCreate)
              FilledButton(
                onPressed: _openCreate,
                child: const Text('Créer un événement'),
              ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _weddings.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final w = _weddings[index];
          return _WeddingCard(wedding: w);
        },
      ),
    );
  }
}

class _WeddingCard extends StatelessWidget {
  const _WeddingCard({required this.wedding});

  final Wedding wedding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.event),
        ),
        title: Text(wedding.displayName),
        subtitle: Text(_statusLabel(wedding.status)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WeddingDetailPage(wedding: wedding),
          ),
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'PUBLISHED' => 'Publié',
      'ACTIVE' => 'Actif',
      'COMPLETED' => 'Terminé',
      'ARCHIVED' => 'Archivé',
      'CANCELLED' => 'Annulé',
      _ => 'Brouillon',
    };
