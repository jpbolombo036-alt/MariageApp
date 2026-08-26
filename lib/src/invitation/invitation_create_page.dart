import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guest/guest_api.dart';
import '../guest/guest_providers.dart';
import 'invitation_api.dart';
import 'invitation_providers.dart';

/// Écran de création d'une invitation : choisir un invité (liste) → POST.
class InvitationCreatePage extends ConsumerStatefulWidget {
  const InvitationCreatePage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<InvitationCreatePage> createState() => _InvitationCreatePageState();
}

class _InvitationCreatePageState extends ConsumerState<InvitationCreatePage> {
  bool _loading = true;
  String? _error;
  List<Guest> _guests = const [];
  int? _selectedGuestId;
  bool _submitting = false;

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

  Future<void> _submit() async {
    if (_selectedGuestId == null) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(invitationApiProvider);
      await api.create(
        widget.weddingId,
        CreateInvitationRequest(guestId: _selectedGuestId!),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une invitation'),
      ),
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
    if (_guests.isEmpty) {
      return Center(child: const Text('Aucun invité disponible'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefreshIndicator(
          onRefresh: _loadGuests,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _guests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final g = _guests[index];
              return ListTile(
                leading: Icon(
                  _selectedGuestId == g.id ? Icons.check_circle : Icons.circle,
                ),
                title: Text(g.displayName),
                subtitle: Text(g.email ?? ''),
                onTap: () => setState(() => _selectedGuestId = g.id),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: (_selectedGuestId == null || _submitting) ? null : _submit,
          child: const Text('Créer l’invitation'),
        ),
      ],
    );
  }
}