import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'checkin_api.dart';
import 'checkin_providers.dart';

/// Accès public (invité) : consulter son invitation et répondre au RSVP.
class PublicRsvpPage extends ConsumerStatefulWidget {
  const PublicRsvpPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<PublicRsvpPage> createState() => _PublicRsvpPageState();
}

class _PublicRsvpPageState extends ConsumerState<PublicRsvpPage> {
  late final TextEditingController _tokenController;

  bool _loading = false;
  String? _error;
  PublicInvitation? _invitation;
  int _attendees = 1;
  bool _submitting = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
    if ((widget.initialToken ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final api = ref.read(checkInApiProvider);
      final inv = await api.getPublicInvitation(token);
      // Consomme aussi le RSVP courant depuis la réponse publique.
      if (!mounted) return;
      setState(() {
        _invitation = inv;
        _attendees = (inv.rsvpNumberOfAttendees ?? 1).clamp(1, 20);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Invitation introuvable';
        _loading = false;
      });
    }
  }

  Future<void> _submit(String status) async {
    final inv = _invitation;
    if (inv == null) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(checkInApiProvider);
      final result = await api.submitRsvp(
        publicToken: _tokenController.text.trim(),
        status: status,
        numberOfAttendees: status == 'ACCEPTED' ? _attendees : 0,
      );
      if (!mounted) return;
      setState(() {
        _result =
            'Réponse enregistrée : ${result.rsvpStatus}'
            ' (${result.numberOfAttendees} personne(s))';
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = 'Échec de l’enregistrement de la réponse';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Répondre à l’invitation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Code d’invitation',
                hintText: 'Collez le lien de votre invitation',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _lookup,
              child: const Text('Consulter'),
            ),
            const SizedBox(height: 20),
            _buildInvitation(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvitation() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final inv = _invitation;
    if (inv == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invité : ${inv.guestFirstName ?? ''} ${inv.guestLastName ?? ''}'),
        Text('Événement : ${inv.weddingDisplayName ?? ''}'),
        const SizedBox(height: 16),
        Text('Votre réponse actuelle : ${inv.rsvpStatus ?? 'Aucune'}'),
        const SizedBox(height: 8),
        Text(
          'Nombre de personnes',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Moins',
              icon: const Icon(Icons.remove),
              onPressed: () => setState(() {
                _attendees = (_attendees > 1 ? _attendees - 1 : 1);
              }),
            ),
            Text(
              '$_attendees',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              tooltip: 'Plus',
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                _attendees = _attendees + 1;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting ? null : () => _submit('ACCEPTED'),
          child: const Text('Accepter (j’y serai)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _submitting ? null : () => _submit('DECLINED'),
          child: const Text('Refuser'),
        ),
      ],
    );
  }
}