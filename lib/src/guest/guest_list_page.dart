import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'category_list_page.dart';
import 'guest_api.dart';
import 'guest_create_page.dart';
import 'guest_providers.dart';

/// Écran invités d'un événement : liste + création + accès aux catégories.
/// Les actions sont conditionnées par les permissions (`GUEST_VIEW`,
/// `GUEST_CREATE`, `CATEGORY_VIEW`...).
class GuestListPage extends ConsumerStatefulWidget {
  const GuestListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends ConsumerState<GuestListPage> {
  bool _loading = true;
  String? _error;
  List<Guest> _guests = const [];

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

  Future<void> _openCreate() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.guestCreate);
    final canViewCategories = auth.hasPermission(PermissionCodes.categoryView);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invités'),
        actions: [
          if (canViewCategories)
            IconButton(
              tooltip: 'Catégories',
              icon: const Icon(Icons.label),
              onPressed: _openCategories,
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: 'Ajouter un invité',
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canCreate),
    );
  }

  void _openCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryListPage(weddingId: widget.weddingId),
      ),
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
    if (_guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aucun invité pour le moment'),
            if (canCreate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _openCreate,
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
        itemCount: _guests.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final g = _guests[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(),
              title: Text(g.displayName),
              subtitle: Text(_guestSubtitle(g)),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
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