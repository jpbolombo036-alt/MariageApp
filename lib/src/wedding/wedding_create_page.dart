import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wedding_api.dart';
import 'wedding_providers.dart';

/// Formulaire de création d'un événement (Wedding).
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

  bool _submitting = false;

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
      groomFirstName: _groomFirstController.text.trim(),
      groomLastName: _groomLastController.text.trim(),
      brideFirstName: _brideFirstController.text.trim(),
      brideLastName: _brideLastController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    try {
      final api = ref.read(weddingApiProvider);
      await api.create(request);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              TextFormField(
                controller: _groomLastController,
                decoration: const InputDecoration(labelText: 'Nom principal'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _brideFirstController,
                decoration: const InputDecoration(labelText: 'Prénom secondaire'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _brideLastController,
                decoration: const InputDecoration(labelText: 'Nom secondaire'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text('Créer l’événement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}