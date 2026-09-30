import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'table_api.dart';
import 'table_assign_page.dart';
import 'table_providers.dart';

/// Écran tables d'un événement : liste, création, et accès aux affectations.
/// Les actions sont conditionnées par les permissions.
class TableListPage extends ConsumerStatefulWidget {
  const TableListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<TableListPage> createState() => _TableListPageState();
}

class _TableListPageState extends ConsumerState<TableListPage> {
  bool _loading = true;
  String? _error;
  List<WeddingTable> _tables = const [];

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
      final api = ref.read(tableApiProvider);
      final items = await api.list(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _tables = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les tables';
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CreateTableDialog(),
    );
    if (raw == null || raw.trim().isEmpty) return;
    // Format "nom|cap" renvoyé par le dialogue.
    final parts = raw.split('|');
    final name = parts[0].trim();
    final capacity = parts.length > 1 ? (int.tryParse(parts[1]) ?? 10) : 10;
    if (name.isEmpty) return;
    try {
      final api = ref.read(tableApiProvider);
      await api.create(
        widget.weddingId,
        CreateWeddingTableRequest(name: name, capacity: capacity),
      );
      _load();
    } catch (_) {
      // échec silencieux
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.tableCreate);

    return Scaffold(
      appBar: AppBar(title: const Text('Tables')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_tables.isEmpty) {
      return Center(child: Text('Aucune table'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _tables.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = _tables[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.table_restaurant)),
            title: Text(t.name),
            subtitle: Text(
              '${t.assignedCount}/${t.capacity} · restants ${t.remainingCapacity}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TableAssignPage(weddingId: widget.weddingId, table: t),
                ),
              );
              if (mounted) await _load();
            },
          ),
        );
      },
    );
  }
}

/// Boîte de dialogue de création d'une table : nom + capacité.
class _CreateTableDialog extends StatefulWidget {
  const _CreateTableDialog();

  @override
  State<_CreateTableDialog> createState() => _CreateTableDialogState();
}

class _CreateTableDialogState extends State<_CreateTableDialog> {
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '10');

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacité'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final cap = int.tryParse(_capacityController.text.trim());
            final name = _nameController.text.trim();
            Navigator.of(context).pop(
              cap != null && cap > 0 ? '$name|$cap' : name,
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}