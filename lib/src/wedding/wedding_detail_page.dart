import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import '../checkin/checkin_scan_page.dart';
import '../dashboard/dashboard_page.dart';
import '../guest/guest_list_page.dart';
import '../invitation/invitation_list_page.dart';
import '../table/table_list_page.dart';
import 'wedding_api.dart';
import 'wedding_providers.dart';

class WeddingDetailPage extends ConsumerStatefulWidget {
  const WeddingDetailPage({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<WeddingDetailPage> createState() => _WeddingDetailPageState();
}

class _WeddingDetailPageState extends ConsumerState<WeddingDetailPage> {
  bool _loading = true;
  String? _error;
  Wedding? _wedding;

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
      final item = await ref.read(weddingApiProvider).getById(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _wedding = item;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger l’événement';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    final canManageGuests = auth.hasPermission(PermissionCodes.guestView);
    final canManageInvitations = auth.hasPermission(PermissionCodes.invitationView);
    final canManageTables = auth.hasPermission(PermissionCodes.tableCreate);
    final canCheckin = auth.hasPermission(PermissionCodes.checkinCreate);
    final canViewDashboard = auth.hasPermission(PermissionCodes.dashboardView);

    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
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
              : _buildDetail(context, canManageGuests, canManageInvitations, canManageTables, canCheckin, canViewDashboard),
    );
  }

  Widget _buildDetail(BuildContext context, bool canManageGuests, bool canManageInvitations, bool canManageTables, bool canCheckin, bool canViewDashboard) {
    final w = _wedding;
    if (w == null) {
      return const Center(child: Text('Événement introuvable'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.displayName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${_typeLabel(w.eventTypeEnum)} · ${_statusLabel(w.status)}'),
                if (w.description != null && w.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(w.description!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (canViewDashboard)
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DashboardPage(weddingId: widget.weddingId, weddingName: w.displayName),
                ),
              );
            },
            child: const Text('Voir le tableau de bord'),
          ),
        const SizedBox(height: 12),
        if (canManageGuests)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GuestListPage(weddingId: widget.weddingId),
                ),
              );
            },
            child: const Text('Gérer les invités'),
          ),
        const SizedBox(height: 12),
        if (canManageInvitations)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvitationListPage(weddingId: widget.weddingId),
                ),
              );
            },
            child: const Text('Invitations & QR'),
          ),
        const SizedBox(height: 12),
        if (canCheckin)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckInScanPage(weddingId: widget.weddingId),
                ),
              );
            },
            child: const Text('Accueil — enregistrement'),
          ),
        const SizedBox(height: 12),
        if (canManageTables)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TableListPage(weddingId: widget.weddingId),
                ),
              );
            },
            child: const Text('Tables & affectations'),
          ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
        'PUBLISHED' => 'Publié',
        'ACTIVE' => 'Actif',
        'COMPLETED' => 'Terminé',
        'ARCHIVED' => 'Archivé',
        'CANCELLED' => 'Annulé',
        _ => 'Brouillon',
      };

  String _typeLabel(EventType? type) {
    return switch (type) {
      EventType.wedding => 'Mariage',
      EventType.collation => 'Collation',
      EventType.anniversary => 'Anniversaire',
      EventType.baptism => 'Baptême',
      EventType.graduation => 'Graduation',
      EventType.other => 'Autre',
      _ => 'Événement',
    };
  }
}
