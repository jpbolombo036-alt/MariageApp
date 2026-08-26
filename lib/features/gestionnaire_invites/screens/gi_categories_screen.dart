import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/theme/gi_ui.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';

/// Écran « Catégories » du rôle GESTIONNAIRE_INVITES.
class GiCategoriesScreen extends ConsumerStatefulWidget {
  const GiCategoriesScreen({super.key});

  @override
  ConsumerState<GiCategoriesScreen> createState() => _GiCategoriesScreenState();
}

class _GiCategoriesScreenState extends ConsumerState<GiCategoriesScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = true;
  String? _error;
  Wedding? _wedding;
  List<GuestCategory> _categories = const [];
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final weddings = await ref.read(weddingApiProvider).list(size: 1);
      if (!mounted) return;
      if (weddings.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      final w = weddings.first;
      final cats =
          await ref.read(guestApiProvider).listCategories(w.id, size: 100);
      if (!mounted) return;
      setState(() { _wedding = w; _categories = cats; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur'; });
    }
  }

  bool get _canCreate =>
      ref.read(authControllerProvider).hasPermission(PermissionCodes.categoryCreate);

  Future<void> _create() async {
    final w = _wedding;
    if (w == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    try {
      await ref.read(guestApiProvider).createCategory(w.id,
          CreateGuestCategoryRequest(
              name: name, description: _descController.text.trim()));
      _nameController.clear();
      _descController.clear();
      setState(() => _adding = false);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de créer la catégorie')));
    }
  }

  void _openCreate() {
    final scheme = GiPalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nouvelle catégorie',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: scheme.textPrimary)),
          const SizedBox(height: 12),
          _field(_nameController, 'Nom *', 'Ex. Famille', scheme),
          const SizedBox(height: 12),
          _field(_descController, 'Description', 'Optionnel', scheme),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: FilledButton(
              onPressed: _adding ? null : _create,
              style: FilledButton.styleFrom(backgroundColor: GiColors.primary),
              child: _adding
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : const Text('Ajouter',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20, color: p.textPrimary)),
        title: Text('Catégories', style: TextStyle(color: p.textPrimary)),
      ),
      body: SafeArea(child: _body(context, p)),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: GiColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _body(BuildContext context, GiPalette p) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(strokeWidth: 2.6, color: p.primary));
    }
    if (_error != null) {
      return Center(
          child: Text('Impossible de charger les catégories',
              style: TextStyle(fontSize: 13, color: p.textSecondary)));
    }
    if (_categories.isEmpty) {
      return Center(
          child: Text('Aucune catégorie',
              style: TextStyle(fontSize: 14, color: p.textSecondary)));
    }
    return RefreshIndicator(
      color: p.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = _categories[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(GiRadius.card),
              border: Border.all(color: p.border),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: GiColors.primaryLightBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.label_outline,
                      size: 20, color: GiColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  if ((c.description ?? '').isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(c.description!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint,
      GiPalette p) {
    return TextField(
      controller: c,
      style: TextStyle(fontSize: 14, color: p.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: p.fieldFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GiRadius.field),
            borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GiRadius.field),
            borderSide: BorderSide(color: p.border)),
      ),
    );
  }
}