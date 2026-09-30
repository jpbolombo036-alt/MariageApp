import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/event_media/event_media_api.dart';
import '../../../../src/event_media/event_media_providers.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/invitation/invitation_providers.dart';

/// Outils d'un événement : relances, import, exports, galerie, boissons.
class EventToolsScreen extends ConsumerStatefulWidget {
  const EventToolsScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<EventToolsScreen> createState() => _EventToolsScreenState();
}

class _EventToolsScreenState extends ConsumerState<EventToolsScreen> {
  final _csv = TextEditingController();
  final _drink = TextEditingController();
  bool _loading = true;
  String? _error;
  int _pending = 0;
  bool _galleryOn = false;
  List<GalleryPhoto> _photos = const [];
  List<EventDrink> _drinks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _csv.dispose();
    _drink.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final media = ref.read(eventMediaApiProvider);
      final pending = await ref.read(invitationApiProvider).countNonResponders(widget.weddingId);
      final gallery = await media.gallery(widget.weddingId);
      final drinks = await media.drinks(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _photos = gallery.photos;
        _galleryOn = gallery.enabled;
        _drinks = drinks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Chargement impossible';
      });
    }
  }

  Future<void> _import() async {
    final csv = _csv.text.trim();
    if (csv.isEmpty) return;
    try {
      final result = await ref.read(guestApiProvider).importGuestsCsv(widget.weddingId, csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import terminé : $result')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import refusé : $e')),
      );
    }
  }

  Future<void> _export(String kind, String label) async {
    try {
      final file = await ref.read(eventMediaApiProvider).downloadExport(widget.weddingId, kind);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label enregistré : ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible : $e')),
      );
    }
  }

  Future<void> _deleteDrink(EventDrink drink) async {
    try {
      await ref.read(eventMediaApiProvider).deleteDrink(widget.weddingId, drink.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boisson non supprimée')),
      );
    }
  }

  Future<void> _deletePhoto(GalleryPhoto photo) async {
    try {
      await ref.read(eventMediaApiProvider).deletePhoto(widget.weddingId, photo.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo non supprimée')),
      );
    }
  }

  Future<void> _addDrink() async {
    final name = _drink.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(eventMediaApiProvider).createDrink(widget.weddingId, name);
      _drink.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Boisson non ajoutée : $e')),
      );
    }
  }

  Future<void> _toggleGallery(bool value) async {
    try {
      await ref.read(eventMediaApiProvider).updateGallery(widget.weddingId, enabled: value);
      setState(() => _galleryOn = value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galerie non mise à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outils de l’événement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) Text(_error!),
                Text('Sans réponse : $_pending'),
                const SizedBox(height: 16),
                const Text('Importer des invités (CSV)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _csv,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'firstName,lastName,email,phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _import, child: const Text('Importer')),
                const SizedBox(height: 20),
                const Text('Exports'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _export('guests/csv', 'Invités CSV'),
                      child: const Text('Invités'),
                    ),
                    OutlinedButton(
                      onPressed: () => _export('invitations/csv', 'Invitations CSV'),
                      child: const Text('Invitations'),
                    ),
                    OutlinedButton(
                      onPressed: () => _export('rsvps/csv', 'RSVP CSV'),
                      child: const Text('RSVP'),
                    ),
                    OutlinedButton(
                      onPressed: () => _export('tables/csv', 'Tables CSV'),
                      child: const Text('Tables'),
                    ),
                    OutlinedButton(
                      onPressed: () => _export('guests/xlsx', 'Invités Excel'),
                      child: const Text('Excel'),
                    ),
                    OutlinedButton(
                      onPressed: () => _export('report/pdf', 'Rapport PDF'),
                      child: const Text('PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Galerie (${_photos.length} photo(s))'),
                  value: _galleryOn,
                  onChanged: _toggleGallery,
                ),
                for (final photo in _photos)
                  ListTile(
                    dense: true,
                    title: Text(photo.caption?.isNotEmpty == true ? photo.caption! : 'Photo ${photo.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deletePhoto(photo),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text('Boissons'),
                for (final drink in _drinks)
                  ListTile(
                    dense: true,
                    title: Text(drink.name),
                    subtitle: drink.description == null ? null : Text(drink.description!),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteDrink(drink),
                    ),
                  ),
                TextField(
                  controller: _drink,
                  decoration: const InputDecoration(labelText: 'Nouvelle boisson'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _addDrink, child: const Text('Ajouter la boisson')),
              ],
            ),
    );
  }
}
