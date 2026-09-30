import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'wedding_api.dart';
import 'wedding_providers.dart';
import '../admin/admin_providers.dart';

/// Formulaire de création d'un événement (Wedding).
/// Le champ «Type d'événement» propose WEDDING, BIRTHDAY, GRADUATION, PARTY,
/// CONFERENCE, OTHER (le backend crée toujours une entité Wedding, mais son
/// `eventType` précise la nature).
class WeddingCreatePage extends ConsumerStatefulWidget {
  const WeddingCreatePage({super.key});

  @override
  ConsumerState<WeddingCreatePage> createState() => _WeddingCreatePageState();
}

class _WeddingCreatePageState extends ConsumerState<WeddingCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _groomFirstController = TextEditingController();
  final _groomLastController = TextEditingController();
  final _brideFirstController = TextEditingController();
  final _brideLastController = TextEditingController();
  final _descriptionController = TextEditingController();

  EventType _eventType = EventType.wedding;
  bool _submitting = false;
  File? _groomPhoto;
  File? _bridePhoto;
  File? _couplePhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardCreation());
  }

  Future<void> _guardCreation() async {
    try {
      final enabled = await ref.read(adminApiProvider).isEventCreationEnabled();
      if (!mounted || enabled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La création d’événements est désactivée')),
      );
      Navigator.of(context).pop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _groomFirstController.dispose();
    _groomLastController.dispose();
    _brideFirstController.dispose();
    _brideLastController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final request = CreateWeddingRequest(
      name: '${_groomFirstController.text.trim()} '
          '& ${_brideFirstController.text.trim()}',
      eventType: _eventType,
      groomFirstName: _groomFirstController.text.trim(),
      groomLastName: _groomLastController.text.trim(),
      brideFirstName: _brideFirstController.text.trim(),
      brideLastName: _brideLastController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      displayName: '${_groomFirstController.text.trim()} & ${_brideFirstController.text.trim()}',
    );

    try {
      final api = ref.read(weddingApiProvider);
      final created = await api.create(request);
      if (!mounted) return;
      if (created.id != 0) {
        await _uploadPhotos(created.id);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _uploadPhotos(int eventId) async {
    final api = ref.read(weddingApiProvider);
    if (_groomPhoto != null) {
      await _uploadPhoto(eventId, 'groom', _groomPhoto!, api);
    }
    if (_bridePhoto != null) {
      await _uploadPhoto(eventId, 'bride', _bridePhoto!, api);
    }
    if (_couplePhoto != null) {
      await _uploadPhoto(eventId, 'couple', _couplePhoto!, api);
    }
  }

  Future<void> _uploadPhoto(int eventId, String kind, File file, WeddingApi api) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      await api.uploadDetailPhoto(eventId, kind, bytes, mime);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _pickPhoto(Future<File?> Function() picker) async {
    final file = await picker();
    if (file != null && mounted) {
      setState(() {});
    }
  }

  String? _photoLabel(File? file) {
    if (file == null) return null;
    return file.path.split('/').last;
  }

  ListTile _typeTile(EventType type, String label) {
    return ListTile(
      leading: Icon(_eventType == type ? Icons.check_circle : Icons.circle),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() => _eventType = type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _groomFirstController,
                decoration: const InputDecoration(labelText: 'Prénom principal'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _groomLastController,
                decoration: const InputDecoration(labelText: 'Nom principal'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _brideFirstController,
                decoration: const InputDecoration(labelText: 'Prénom secondaire'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _brideLastController,
                decoration: const InputDecoration(labelText: 'Nom secondaire'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _pickPhoto(() async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (file != null) _groomPhoto = File(file.path);
                        return _groomPhoto;
                      }),
                      icon: Icon(
                        _groomPhoto == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline,
                        color: scheme.primary,
                      ),
                      label: Text(
                        _photoLabel(_groomPhoto) ?? 'Photo du marié',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _pickPhoto(() async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (file != null) _bridePhoto = File(file.path);
                        return _bridePhoto;
                      }),
                      icon: Icon(
                        _bridePhoto == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline,
                        color: scheme.primary,
                      ),
                      label: Text(
                        _photoLabel(_bridePhoto) ?? 'Photo de la mariée',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _pickPhoto(() async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (file != null) _couplePhoto = File(file.path);
                  return _couplePhoto;
                }),
                icon: Icon(
                  _couplePhoto == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline,
                  color: scheme.primary,
                ),
                label: Text(
                  _photoLabel(_couplePhoto) ?? 'Photo du couple',
                  style: TextStyle(color: scheme.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Text(
                'Type d’événement',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _typeTile(EventType.wedding, 'Mariage'),
              _typeTile(EventType.collation, 'Collation'),
              _typeTile(EventType.anniversary, 'Anniversaire'),
              _typeTile(EventType.baptism, 'Baptême'),
              _typeTile(EventType.graduation, 'Graduation'),
              _typeTile(EventType.other, 'Autre'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Création…' : 'Créer l’événement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
