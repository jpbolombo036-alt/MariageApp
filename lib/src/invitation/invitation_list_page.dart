import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'invitation_api.dart';
import 'invitation_create_page.dart';
import 'invitation_providers.dart';
import 'invitation_qr_page.dart';

/// Écran invitations d'un événement : liste, création (par invité) et QR.
/// Les actions sont conditionnées par les permissions.
class InvitationListPage extends ConsumerStatefulWidget {
  const InvitationListPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<InvitationListPage> createState() => _InvitationListPageState();
}

class _InvitationListPageState extends ConsumerState<InvitationListPage> {
  bool _loading = true;
  String? _error;
  List<Invitation> _invitations = const [];

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
      final api = ref.read(invitationApiProvider);
      final items = await api.list(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _invitations = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les invitations';
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationCreatePage(weddingId: widget.weddingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.invitationCreate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canCreate),
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
    if (_invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aucune invitation'),
            if (canCreate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _openCreate,
                child: const Text('Créer une invitation'),
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
        itemCount: _invitations.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final inv = _invitations[index];
          return _InvitationCard(
            weddingId: widget.weddingId,
            invitation: inv,
          );
        },
      ),
    );
  }
}

/// Carte d'une invitation : code + statut, avec affichage du QR.
class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.weddingId, required this.invitation});

  final int weddingId;
  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(),
        title: Text(invitation.invitationCode),
        subtitle: Text(_statusLabel(invitation.status)),
        trailing: const Icon(Icons.qr_code),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InvitationQrPage(
              weddingId: weddingId,
              invitation: invitation,
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'GENERATED' => 'Générée',
        'SENT' => 'Envoyée',
        'CANCELLED' => 'Annulée',
        'EXPIRED' => 'Expirée',
        _ => 'Brouillon',
      };
}