import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guest/guest_api.dart';
import '../guest/guest_providers.dart';
import 'table_api.dart';
import 'table_providers.dart';

/// Écran d'affectation d'invités à une table : liste des invités du mariage,
/// sélection d'un invité → affectation à la table courante.
class TableAssignPage extends ConsumerStatefulWidget {
  const TableAssignPage({super.key, required this.weddingId, required this.table});

  final int weddingId;
  final WeddingTable table;

  @override
  ConsumerState<TableAssignPage> createState() => _TableAssignPageState();
}

class _TableAssignPageState extends ConsumerState<TableAssignPage> {
  bool _loading = true;
  String? _error;
  List<Guest> _guests = const [];
  bool _submitting = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  Future<void> _loadGuests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(guestApiProvider);
      final items = await api.listGuests(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _guests = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les invités';
        _loading = false;
      });
    }
  }

  Future<void> _assign(Guest guest) async {
    if (widget.table.remainingCapacity <= 0) return;
    setState(() {
      _submitting = true;
      _result = null;
    });
    try {
      final api = ref.read(tableApiProvider);
      final assignment = await api.assign(
        weddingId: widget.weddingId,
        tableId: widget.table.id,
        guestId: guest.id,
      );
      if (!mounted) return;
      setState(() {
        _result = '${guest.displayName} → ${assignment.tableName}';
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = "Échec de l'affectation";
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    return Scaffold(
      appBar: AppBar(title: Text('Affecter — ${t.name}')),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(WeddingTable t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${t.assignedCount}/${t.capacity} · restants ${t.remainingCapacity}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (_result != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_result!),
          ),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _guests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final g = _guests[index];
              return ListTile(
                leading: const CircleAvatar(),
                title: Text(g.displayName),
                subtitle: Text(g.email ?? ''),
                trailing: const Icon(Icons.assignment_add),
                onTap: _submitting ? null : () => _assign(g),
              );
            },
          ),
        ),
      ],
    );
  }
}