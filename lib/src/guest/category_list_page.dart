import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'guest_api.dart';
import 'guest_providers.dart';

/// Écran des catégories d'invités d'un événement : liste + création.
class CategoryListPage extends ConsumerStatefulWidget {
  const CategoryListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends ConsumerState<CategoryListPage> {
  bool _loading = true;
  String? _error;
  List<GuestCategory> _categories = const [];

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
      final items = await api.listCategories(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _categories = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les catégories';
        _loading = false;
      });
    }
  }

  Future<void> _createCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CategoryNameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final api = ref.read(guestApiProvider);
      await api.createCategory(
        widget.weddingId,
        CreateGuestCategoryRequest(name: name.trim()),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Création impossible')),
      );
    }
  }

  Future<void> _rename(GuestCategory category) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CategoryNameDialog(initial: category.name),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(guestApiProvider).updateCategory(
            widget.weddingId,
            category.id,
            name.trim(),
            description: category.description,
          );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification impossible')),
      );
    }
  }

  Future<void> _delete(GuestCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Retour')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(guestApiProvider).deleteCategory(widget.weddingId, category.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.categoryCreate);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: 'Nouvelle catégorie',
              onPressed: _createCategory,
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
    if (_categories.isEmpty) {
      return Center(child: Text('Aucune catégorie'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _categories.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = _categories[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.label)),
            title: Text(c.name),
            subtitle: c.description != null && c.description!.isNotEmpty
                ? Text(c.description!)
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _rename(c);
                if (value == 'delete') _delete(c);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Renommer')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Boîte de dialogue de création d'une catégorie : saisit un nom et le renvoie.
class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({this.initial = ''});

  final String initial;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial.isEmpty ? 'Nouvelle catégorie' : 'Renommer'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.initial.isEmpty ? 'Créer' : 'Enregistrer'),
        ),
      ],
    );
  }
}