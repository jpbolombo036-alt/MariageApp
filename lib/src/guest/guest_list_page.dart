import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'category_list_page.dart';
import 'guest_api.dart';
import 'guest_create_page.dart';
import 'guest_detail_page.dart';
import 'guest_providers.dart';

class GuestListPage extends ConsumerStatefulWidget {
  const GuestListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends ConsumerState<GuestListPage> {
  bool _loading = true;
  String? _error;
  List<Guest> _items = const [];

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
      final items = await ref.read(guestApiProvider).listGuests(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.guestCreate);
    final canUpdate = auth.hasPermission(PermissionCodes.guestUpdate);
    final canDelete = auth.hasPermission(PermissionCodes.guestDelete);
    final canViewCategories = auth.hasPermission(PermissionCodes.categoryView);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invités'),
        actions: [
          if (canViewCategories)
            IconButton(
              tooltip: 'Catégories',
              icon: const Icon(Icons.label),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryListPage(weddingId: widget.weddingId),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: 'Ajouter un invité',
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
                  ),
                );
                if (created == true && mounted) {
                  _load();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canCreate, canUpdate, canDelete),
    );
  }

  Widget _buildBody(bool canCreate, bool canUpdate, bool canDelete) {
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
            const Text('Aucun invité pour le moment'),
            if (canCreate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
                    ),
                  );
                  if (created == true && mounted) {
                    _load();
                  }
                },
                child: const Text('Ajouter un invité'),
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
          final g = _items[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(),
              title: Text(g.displayName),
              subtitle: Text(_guestSubtitle(g)),
              trailing: (canUpdate || canDelete)
                  ? PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') _edit(context, g);
                        if (action == 'delete') _delete(context, g);
                      },
                      itemBuilder: (context) => [
                        if (canUpdate)
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        if (canDelete)
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    )
                  : null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuestDetailPage(guest: g),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Guest guest) async {
    final first = TextEditingController(text: guest.firstName);
    final last = TextEditingController(text: guest.lastName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l’invité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: first, decoration: const InputDecoration(labelText: 'Prénom')),
            TextField(controller: last, decoration: const InputDecoration(labelText: 'Nom')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enregistrer')),
        ],
      ),
    );
    final firstName = first.text.trim();
    final lastName = last.text.trim();
    first.dispose();
    last.dispose();
    if (saved != true || firstName.isEmpty || lastName.isEmpty) return;
    try {
      await ref.read(guestApiProvider).updateGuest(
            widget.weddingId,
            guest.id,
            UpdateGuestRequest(firstName: firstName, lastName: lastName),
          );
      if (mounted) {
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modification impossible')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, Guest guest) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet invité ?'),
        content: Text(guest.displayName),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(guestApiProvider).deleteGuest(widget.weddingId, guest.id);
      if (mounted) {
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suppression impossible')),
        );
      }
    }
  }

  String _guestSubtitle(Guest g) {
    final parts = <String>[];
    if (g.email != null && g.email!.isNotEmpty) parts.add(g.email!);
    if (g.allowedCompanions != null && g.allowedCompanions! > 0) {
      parts.add('+${g.allowedCompanions} accomp.');
    }
    return parts.join(' · ');
  }
}
