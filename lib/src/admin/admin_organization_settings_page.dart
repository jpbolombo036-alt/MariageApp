import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_button.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminOrganizationSettingsPage extends ConsumerStatefulWidget {
  const AdminOrganizationSettingsPage({super.key, required this.organization});

  final AdminOrganization organization;

  @override
  ConsumerState<AdminOrganizationSettingsPage> createState() => _AdminOrganizationSettingsPageState();
}

class _AdminOrganizationSettingsPageState extends ConsumerState<AdminOrganizationSettingsPage> {
  bool _loading = true;
  String? _error;
  bool _eventCreation = true;
  bool _whatsappEnabled = true;

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
      final api = ref.read(adminApiProvider);
      final settings = await api.organizationSettings(widget.organization.id);
      if (!mounted) return;
      setState(() {
        _eventCreation = (settings['eventCreationEnabled'] as bool?) ?? true;
        _whatsappEnabled = (settings['whatsappEnabled'] as bool?) ?? true;
        _loading = false;
      });
    } on AppFailure catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les réglages';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les réglages';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    try {
      await ref.read(adminApiProvider).updateOrganizationSettings(
            widget.organization.id,
            eventCreationEnabled: _eventCreation,
            whatsappEnabled: _whatsappEnabled,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réglages enregistrés')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement impossible')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réglages · ${widget.organization.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SwitchListTile(
                      title: const Text('Création d’événements'),
                      subtitle: const Text('Autoriser la création pour cette organisation'),
                      value: _eventCreation,
                      onChanged: (v) => setState(() => _eventCreation = v),
                    ),
                    SwitchListTile(
                      title: const Text('Envoi WhatsApp'),
                      subtitle: const Text('Autoriser les envois WhatsApp'),
                      value: _whatsappEnabled,
                      onChanged: (v) => setState(() => _whatsappEnabled = v),
                    ),
                    const SizedBox(height: 16),
                    AppButton(label: 'Enregistrer', fullWidth: true, onPressed: _save),
                  ],
                ),
    );
  }
}
