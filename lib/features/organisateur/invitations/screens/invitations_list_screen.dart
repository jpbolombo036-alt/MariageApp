import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/admin/admin_api.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/invitation/invitation_api.dart';
import '../../../../src/invitation/invitation_providers.dart';
import '../../../../src/theme/invitation_ui.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../widgets/event_selector_card.dart';
import '../widgets/invitation_card.dart';
import '../widgets/invitation_filters.dart';
import '../widgets/invitation_stats_card.dart';
import '../widgets/invitation_states.dart';
import 'invitation_create_screen.dart';
import 'invitation_details_screen.dart';

/// Vue de ligne : une invitation enrichie de son invité.
class InvitationRow {
  const InvitationRow({required this.invitation, this.guest});

  final Invitation invitation;
  final Guest? guest;

  String get guestName {
    final g = guest;
    if (g != null) {
      final n = '${g.firstName} ${g.lastName}'.trim();
      if (n.isNotEmpty) return n;
    }
    return 'Invité';
  }

  String get guestEmail => guest?.email ?? '';
  String get guestPhone => guest?.phone ?? '';

  int get maxPersons {
    final g = guest;
    if (g != null && g.allowedCompanions != null) return 1 + g.allowedCompanions!;
    return 1;
  }
}

/// Écran principal — liste des invitations.
class InvitationsListScreen extends ConsumerStatefulWidget {
  const InvitationsListScreen({super.key});

  @override
  ConsumerState<InvitationsListScreen> createState() =>
      _InvitationsListScreenState();
}

class _InvitationsListScreenState
    extends ConsumerState<InvitationsListScreen> {
  static const _filters = <String>[
    'Toutes',
    'Brouillons',
    'Générées',
    'Envoyées',
    'Annulées',
    'Expirées',
  ];

  final _searchController = TextEditingController();

  bool _loading = true;
  bool _waEnabled = true;
  bool _bulkSending = false;
  String? _error;
  Wedding? _wedding;
  Dashboard? _dashboard;
  List<InvitationRow> _rows = const [];
  String _selectedFilter = 'Toutes';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Interrupteur plateforme : l'envoi WhatsApp peut être coupé par le
      // super-admin (les points d'entrée WhatsApp sont alors masqués).
      try {
        final adminApi = AdminApi(api: ref.read(apiClientProvider));
        _waEnabled = await adminApi.isWhatsappSendingEnabled();
      } catch (_) {
        _waEnabled = true;
      }
      final weddings = await ref.read(weddingApiProvider).list(size: 25);
      if (!mounted) return;
      if (weddings.isEmpty) {
        setState(() {
          _loading = false;
          _wedding = null;
          _rows = const [];
        });
        return;
      }
      final wedding = weddings.first;
      final guestApi = ref.read(guestApiProvider);
      final invApi = ref.read(invitationApiProvider);
      final results = await Future.wait([
        guestApi.listGuests(wedding.id, size: 200),
        invApi.list(wedding.id, size: 200),
      ]);
      if (!mounted) return;
      final guests = results[0] as List<Guest>;
      final invs = results[1] as List<Invitation>;
      Dashboard? dash;
      try {
        dash = await ref.read(dashboardApiProvider).getForWedding(wedding.id);
      } catch (_) {
        dash = null;
      }
      if (!mounted) return;
      final rows = <InvitationRow>[];
      for (final inv in invs) {
        Guest? g;
        for (final guest in guests) {
          if (guest.id == inv.guestId) {
            g = guest;
            break;
          }
        }
        rows.add(InvitationRow(invitation: inv, guest: g));
      }
      setState(() {
        _wedding = wedding;
        _dashboard = dash;
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur';
      });
    }
  }

  Future<void> _refresh() => _load();

  /// Envoi en masse des invitations jamais envoyées (WhatsApp).
  Future<void> _bulkSendWhatsapp() async {
    final wedding = _wedding;
    if (wedding == null || _bulkSending) return;
    final targets = _rows
        .where((r) {
          final s = r.invitation.status.toUpperCase().trim();
          return s == 'GENERATED' || s == 'DRAFT';
        })
        .map((r) => r.invitation.id)
        .toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Aucune invitation à envoyer : toutes sont déjà envoyées, annulées ou expirées.'),
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer sur WhatsApp'),
        content: Text(
            "Envoyer ${targets.length} invitation(s) par WhatsApp ?\n\n"
            "Chaque invité reçoit le modèle approuvé : son prénom, le nom du "
            "couple, la date, l'heure, le lieu et un bouton vers son invitation."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _bulkSending = true);
    try {
      final invApi = ref.read(invitationApiProvider);
      final batch =
          await invApi.startBulkSend(wedding.id, BulkSendRequest(invitationIds: targets));
      if (!mounted) return;
      await _showBulkProgressDialog(wedding.id, batch);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Impossible de démarrer l'envoi en masse (vérifiez la configuration WhatsApp)."),
        ));
      }
    } finally {
      if (mounted) setState(() => _bulkSending = false);
    }
  }

  /// Boîte de dialogue de progression (polling du batch toutes les 2 s).
  Future<void> _showBulkProgressDialog(int weddingId, BulkSendBatch batch) async {
    final notifier = ValueNotifier<BulkSendBatch>(batch);
    var failures = <BulkSendLog>[];
    unawaited(_pollBulkBatch(weddingId, notifier, (list) => failures = list));
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: ValueListenableBuilder<BulkSendBatch>(
          valueListenable: notifier,
          builder: (_, b, _) =>
              Text(b.isFinished ? 'Envoi terminé' : 'Envoi en cours…'),
        ),
        content: ValueListenableBuilder<BulkSendBatch>(
          valueListenable: notifier,
          builder: (_, b, _) {
            final processed = b.sentCount + b.failedCount + b.skippedCount;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: b.totalCount == 0
                      ? null
                      : (processed / b.totalCount).clamp(0.0, 1.0),
                  color: InvColors.whatsapp,
                ),
                const SizedBox(height: 12),
                Text(
                    'Envoyées : ${b.sentCount}   ·   Échecs : ${b.failedCount}   ·   Ignorés : ${b.skippedCount}'),
                const SizedBox(height: 6),
                Text('Total : ${b.totalCount}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (b.isFinished && failures.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Échecs :',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final l in failures.take(5))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${l.errorMessage ?? 'erreur'}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (failures.length > 5)
                    Text('… et ${failures.length - 5} autre(s)',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            );
          },
        ),
        actions: [
          ValueListenableBuilder<BulkSendBatch>(
            valueListenable: notifier,
            builder: (ctx, b, _) => TextButton(
              onPressed: b.isFinished ? () => Navigator.pop(ctx) : null,
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
    notifier.dispose();
    await _refresh();
  }

  /// Interroge le batch toutes les 2 s jusqu'à COMPLETED / FAILED.
  Future<void> _pollBulkBatch(int weddingId, ValueNotifier<BulkSendBatch> notifier,
      void Function(List<BulkSendLog>) onFailures) async {
    var b = notifier.value;
    var guard = 0;
    while (!b.isFinished && guard < 300) {
      await Future.delayed(const Duration(seconds: 2));
      guard++;
      try {
        b = await ref.read(invitationApiProvider).getBulkBatch(weddingId, b.id);
      } catch (_) {
        continue;
      }
      notifier.value = b;
    }
    if (b.isFinished) {
      try {
        final logs =
            await ref.read(invitationApiProvider).getBulkBatchLogs(weddingId, b.id);
        onFailures(logs.where((l) => l.status == 'FAILED').toList());
        notifier.value = b;
      } catch (_) {
        // le récapitulatif des compteurs suffit
      }
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvitationCreateScreen(weddingId: _wedding?.id),
      ),
    );
    if (created == true && mounted) await _refresh();
  }

  Future<void> _openDetails(InvitationRow row) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InvitationDetailsScreen(row: row)),
    );
    if (mounted) await _refresh();
  }

  int _count(String status) =>
      _rows.where((r) => r.invitation.status.toUpperCase().trim() == status).length;List<InvitationRow> get _filtered {
    final list = _rows.where((r) {
      if (_selectedFilter == 'Toutes') return true;
      final s = r.invitation.status.toUpperCase().trim();
      switch (_selectedFilter) {
        case 'Brouillons':
          return s == 'DRAFT';
        case 'Générées':
          return s == 'GENERATED';
        case 'Envoyées':
          return s == 'SENT';
        case 'Annulées':
          return s == 'CANCELLED' || s == 'CANCELED';
        case 'Expirées':
          return s == 'EXPIRED';
        default:
          return true;
      }
    }).toList();

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((r) => r.guestName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: _loading
            ? const InvitationLoadingState()
            : _error != null
                ? InvitationErrorState(onRetry: _load)
                : _wedding == null
                    ? EmptyInvitationsState(onCreate: _openCreate)
                    : _buildContent(context, p),
      ),
      bottomNavigationBar:
          _wedding == null ? null : _buildActionBar(context, p),
    );
  }

  Widget _buildContent(BuildContext context, InvPalette p) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: InvColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: InvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildHeader(context, p),
            const SizedBox(height: InvSpacing.lg),
            EventSelectorCard(
              title: _wedding!.displayName,
              subtitle: _wedding!.status,
              onTap: () {},
            ),
            const SizedBox(height: InvSpacing.lg),
            InvitationStatsCard(
              total: _rows.length,
              accepted: _dashboard?.invitations.accepted ?? 0,
              declined: _dashboard?.invitations.declined ?? 0,
              pending: _dashboard?.invitations.pending ?? 0,
              cancelled: _count('CANCELLED') + _count('CANCELED'),
            ),
            const SizedBox(height: InvSpacing.lg),
            InvitationSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              onFilterTap: () {},
            ),
            const SizedBox(height: InvSpacing.md),
            InvitationFilterChips(
              options: _filters,
              selected: _selectedFilter,
              onSelected: (v) => setState(() => _selectedFilter = v),
            ),
            const SizedBox(height: InvSpacing.lg),
            if (_rows.isEmpty)
              EmptyInvitationsState(onCreate: _openCreate)
            else
              _buildFilteredList(_filtered),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList(List<InvitationRow> list) {
    if (list.isEmpty && _query.trim().isEmpty) {
      return EmptyInvitationsState(onCreate: _openCreate);
    }
    if (list.isEmpty) {
      return const NoInvitationResultsState();
    }
    return Column(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          InvitationCard(
            guestName: list[i].guestName,
            subtitle: list[i].guestEmail,
            maxPersons: list[i].maxPersons,
            status: list[i].invitation.status,
            metaLeft: sentLabel(list[i].invitation.sentAt),
            metaRight: rsvpText(list[i].invitation.status),
            onTap: () => _openDetails(list[i]),
            onMenu: () => _openDetails(list[i]),
          ),
          if (i < list.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }Widget _buildHeader(BuildContext context, InvPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.menu, size: 24, color: p.textPrimary),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invitations', style: InvType.screenTitle(p.textPrimary)),
              const SizedBox(height: 3),
              Text(
                'Gérez et suivez les invitations de votre événement',
                style: InvType.subtitle(p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 24, color: p.textPrimary),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: InvColors.notification,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context, InvPalette p) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(InvSpacing.lg, 10, InvSpacing.lg, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            if (_waEnabled) ...[
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _bulkSending ? null : _bulkSendWhatsapp,
                      borderRadius: BorderRadius.circular(InvRadius.pill),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: InvColors.whatsapp,
                          borderRadius: BorderRadius.circular(InvRadius.pill),
                        ),
                        child: Center(
                          child: _bulkSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 18, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: invPrimaryGradient,
                      borderRadius: BorderRadius.circular(InvRadius.pill),
                    ),
                    child: InkWell(
                      onTap: _openCreate,
                      borderRadius: BorderRadius.circular(InvRadius.pill),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Nouvelle invitation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}/// Libellé de la date d'envoi d'une invitation.
String sentLabel(String? sentAt) {
  if (sentAt == null || sentAt.isEmpty) return 'Non envoyée';
  final d = sentAt.length >= 10 ? sentAt.substring(0, 10) : sentAt;
  return 'Envoyée le $d';
}

/// Texte affiché à droite de la carte selon le statut réel de l'invitation.
String rsvpText(String? status) {
  switch ((status ?? '').toUpperCase().trim()) {
    case 'DRAFT':
      return 'Brouillon';
    case 'GENERATED':
      return 'Prête à envoyer';
    case 'SENT':
      return 'Envoyée';
    case 'CANCELLED':
    case 'CANCELED':
      return 'Annulée';
    case 'EXPIRED':
      return 'Expirée';
    default:
      return '—';
  }
}