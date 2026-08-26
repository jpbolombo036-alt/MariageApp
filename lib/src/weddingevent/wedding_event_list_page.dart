import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'wedding_event_api.dart';
import 'wedding_event_providers.dart';

/// Écran des événements d'un mariage : liste + création.
class WeddingEventListPage extends ConsumerStatefulWidget {
  const WeddingEventListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<WeddingEventListPage> createState() => _WeddingEventListPageState();
}

class _WeddingEventListPageState extends ConsumerState<WeddingEventListPage> {
  bool _loading = true;
  String? _error;
  List<WeddingEvent> _events = const [];

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
      final api = ref.read(weddingEventApiProvider);
      final items = await api.list(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _events = items;
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
    final canCreate = auth.hasPermission(PermissionCodes.eventCreate);

    return Scaffold(
      appBar: AppBar(title: const Text('Événements')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: 'Ajouter un événement',
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canCreate),
    );
  }

  Future<void> _openCreate() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CreateEventDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final api = ref.read(weddingEventApiProvider);
      await api.create(
        widget.weddingId,
        CreateWeddingEventRequest(name: name.trim(), type: WeddingEventType.reception),
      );
      _load();
    } catch (_) {
      // échec silencieux
    }
  }

  Widget _buildBody(bool canCreate) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aucun événement pour le moment'),
            if (canCreate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _openCreate,
                child: const Text('Ajouter un événement'),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _events.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = _events[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(),
            title: Text(e.name),
            subtitle: Text(_subtitle(e)),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  String _subtitle(WeddingEvent e) {
    final parts = <String>[];
    if (e.typeEnum != null) parts.add(_label(e.typeEnum!));
    if (e.eventDate != null && e.eventDate!.isNotEmpty) parts.add(e.eventDate!);
    if (e.city != null && e.city!.isNotEmpty) parts.add(e.city!);
    return parts.join(' · ');
  }

  String _label(WeddingEventType type) => switch (type) {
        WeddingEventType.civilCeremony => 'Mariage civil',
        WeddingEventType.religiousCeremony => 'Mariage religieux',
        WeddingEventType.reception => 'Réception',
        WeddingEventType.afterParty => 'After-p.' ,
        WeddingEventType.other => 'Autre',
      };
}

/// Boîte de dialogue simple de création d'un événement (nom).
class _CreateEventDialog extends StatefulWidget {
  const _CreateEventDialog();

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvel événement'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}