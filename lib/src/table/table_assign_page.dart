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
  List<WeddingTable> _tables = const [];
  List<TableAssignment> _assignments = const [];
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
      final guests = await ref.read(guestApiProvider).listGuests(widget.weddingId);
      final tables = await ref.read(tableApiProvider).list(widget.weddingId);
      List<TableAssignment> assignments = const [];
      try {
        assignments = await ref.read(tableApiProvider).listAssignments(
              weddingId: widget.weddingId,
              tableId: widget.table.id,
            );
      } catch (_) {
        assignments = const [];
      }
      if (!mounted) return;
      setState(() {
        _guests = guests;
        _tables = tables;
        _assignments = assignments;
        _loading = false;
        _submitting = false;
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
      await _loadGuests();
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

  Future<void> _move(TableAssignment assignment) async {
    final targets = _tables.where((table) => table.id != widget.table.id).toList();
    if (targets.isEmpty) return;
    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Déplacer vers'),
        children: [
          for (final table in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(table.id),
              child: Text(table.name),
            ),
        ],
      ),
    );
    if (targetId == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(tableApiProvider).move(
            weddingId: widget.weddingId,
            assignmentId: assignment.assignmentId,
            targetTableId: targetId,
          );
      if (!mounted) return;
      setState(() => _result = '${assignment.guestName} déplacé');
      await _loadGuests();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = 'Déplacement impossible';
        _submitting = false;
      });
    }
  }

  Future<void> _remove(TableAssignment assignment) async {
    setState(() => _submitting = true);
    try {
      await ref.read(tableApiProvider).remove(
            weddingId: widget.weddingId,
            assignmentId: assignment.assignmentId,
          );
      if (!mounted) return;
      setState(() => _result = '${assignment.guestName} retiré de la table');
      await _loadGuests();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = 'Retrait impossible';
        _submitting = false;
      });
    }
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
        if (_assignments.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _assignments.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final assignment = _assignments[index];
                return ListTile(
                  title: Text(assignment.guestName),
                  subtitle: Text(assignment.tableName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Déplacer',
                        onPressed: _submitting ? null : () => _move(assignment),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      IconButton(
                        tooltip: 'Retirer',
                        onPressed: _submitting ? null : () => _remove(assignment),
                        icon: const Icon(Icons.person_remove_outlined),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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