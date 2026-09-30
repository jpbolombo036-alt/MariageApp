import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guest/guest_api.dart';
import '../guest/guest_create_page.dart';
import '../guest/guest_providers.dart';
import 'invitation_api.dart';
import 'invitation_providers.dart';

/// Écran de création d'une invitation : choisir un invité (liste) → POST.
class InvitationCreatePage extends ConsumerStatefulWidget {
  const InvitationCreatePage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<InvitationCreatePage> createState() =>
      _InvitationCreatePageState();
}

class _InvitationCreatePageState extends ConsumerState<InvitationCreatePage> {
  bool _loading = true;
  String? _error;
  List<Guest> _guests = const [];

  /// Invités ayant déjà une invitation (évite les 409 côté backend).
  Set<int> _alreadyInvited = <int>{};

  int? _selectedGuestId;
  bool _submitting = false;

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
      final guestApi = ref.read(guestApiProvider);
      final invitationApi = ref.read(invitationApiProvider);
      final results = await Future.wait(<Future<Object>>[
        guestApi.listGuests(widget.weddingId),
        invitationApi.list(widget.weddingId),
      ]);
      if (!mounted) return;
      final guests = results[0] as List<Guest>;
      final invitations = results[1] as List<Invitation>;
      setState(() {
        _guests = guests;
        _alreadyInvited = invitations.map((e) => e.guestId).toSet();
        if (_selectedGuestId != null &&
            _alreadyInvited.contains(_selectedGuestId)) {
          _selectedGuestId = null;
        }
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
    final guestId = _selectedGuestId;
    if (guestId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(invitationApiProvider);
      await api.create(
        widget.weddingId,
        CreateInvitationRequest(guestId: guestId),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_messageOf(error))));
    }
  }

  /// Message lisible pour l'utilisateur à partir d'une erreur Dio.
  String _messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      switch (error.response?.statusCode) {
        case 400:
          return 'Données invalides : vérifiez l\'invité sélectionné';
        case 403:
          return 'Action non autorisée pour votre rôle';
        case 404:
          return 'Invité ou événement introuvable';
        case 409:
          return 'Une invitation existe déjà pour cet invité';
      }
      return 'Création impossible (${error.response?.statusCode ?? 'réseau'})';
    }
    return 'Création impossible';
  }

  Future<void> _addGuest() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
      ),
    );
    if (created == true) await _load();
  }

  void _onGuestTap(Guest guest, bool hasInvitation) {
    if (hasInvitation) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Une invitation existe déjà pour ${guest.displayName}',
            ),
          ),
        );
      return;
    }
    setState(() => _selectedGuestId = guest.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une invitation')),
      body: SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_guests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              const Text('Aucun invité disponible'),
              const SizedBox(height: 4),
              Text(
                'Ajoutez d\'abord un invité, puis créez son invitation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addGuest,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un invité'),
              ),
            ],
          ),
        ),
      );
    }

    final availableCount =
        _guests.where((g) => !_alreadyInvited.contains(g.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La liste DOIT être contrainte (Expanded) : dans une Column, une
        // ListView non bornée lève « unbounded height » et casse l'écran.
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _guests.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final guest = _guests[index];
                final hasInvitation = _alreadyInvited.contains(guest.id);
                final selected = _selectedGuestId == guest.id;
                return ListTile(
                  enabled: !hasInvitation,
                  leading: Icon(
                    hasInvitation
                        ? Icons.mark_email_read_outlined
                        : (selected
                              ? Icons.check_circle
                              : Icons.circle_outlined),
                    color: hasInvitation
                        ? theme.colorScheme.outline
                        : (selected ? theme.colorScheme.primary : null),
                  ),
                  title: Text(guest.displayName),
                  subtitle: Text(
                    hasInvitation
                        ? 'Invitation déjà créée'
                        : (guest.email ?? guest.phone ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: hasInvitation
                      ? const Icon(Icons.lock_outline, size: 18)
                      : null,
                  onTap: () => _onGuestTap(guest, hasInvitation),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                availableCount == 0
                    ? 'Tous les invités ont déjà une invitation'
                    : '$availableCount invité(s) sans invitation',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (_selectedGuestId == null || _submitting)
                    ? null
                    : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer l\'invitation'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}