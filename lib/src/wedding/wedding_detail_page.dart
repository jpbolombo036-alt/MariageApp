import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import '../checkin/checkin_scan_page.dart';
import '../dashboard/dashboard_page.dart';
import '../guest/guest_list_page.dart';
import '../invitation/invitation_list_page.dart';
import '../table/table_list_page.dart';
import '../weddingevent/wedding_event_list_page.dart';
import 'wedding_api.dart';

/// Détail d'un événement (Wedding) : informations + accès au dashboard.
class WeddingDetailPage extends ConsumerWidget {
  const WeddingDetailPage({super.key, required this.wedding});

  final Wedding wedding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = wedding;
    final auth = ref.watch(authControllerProvider);
    final showDashboard = auth.hasPermission(PermissionCodes.dashboardView);
    final showGuests = auth.hasPermission(PermissionCodes.guestView);
    final showInvitations = auth.hasPermission(PermissionCodes.invitationView);
    final showCheckIn = auth.hasPermission(PermissionCodes.checkinCreate);
    final showTables = auth.hasPermission(PermissionCodes.tableCreate);
    final showEvents = auth.hasPermission(PermissionCodes.eventView);

    return Scaffold(
      appBar: AppBar(
        title: Text(w.displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('Événement'),
                     const SizedBox(height: 4),
                     Text('Statut : ${_statusLabel(w.status)}'),
                    const SizedBox(height: 8),
                    Text('${w.groomFirstName} ${w.groomLastName}'),
                    if (w.brideFirstName.isNotEmpty || w.brideLastName.isNotEmpty)
                      Text('${w.brideFirstName} ${w.brideLastName}'),
                    if (w.description != null && w.description!.isNotEmpty)
                      Text(w.description!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (showDashboard) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DashboardPage(
                      weddingId: w.id,
                      weddingName: w.displayName,
                    ),
                  ),
                ),
                child: const Text('Voir le tableau de bord'),
              ),
              const SizedBox(height: 12),
            ],
            if (showGuests) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuestListPage(weddingId: w.id),
                  ),
                ),
                child: const Text('Gérer les invités'),
              ),
              const SizedBox(height: 12),
            ],
            if (showInvitations) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvitationListPage(weddingId: w.id),
                  ),
                ),
                child: const Text('Invitations & QR'),
              ),
              const SizedBox(height: 12),
            ],
            if (showCheckIn) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CheckInScanPage(),
                  ),
                ),
                child: const Text('Accueil — enregistrement'),
              ),
              const SizedBox(height: 12),
            ],
            if (showEvents)
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WeddingEventListPage(weddingId: w.id),
                  ),
                ),
                child: const Text('Événements'),
              ),
            if (showTables)
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TableListPage(weddingId: w.id),
                  ),
                ),
                child: const Text('Tables & affectations'),
              ),
          ],
        ),
      ),
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
}