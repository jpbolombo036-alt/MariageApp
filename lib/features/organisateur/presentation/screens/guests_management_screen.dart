import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_models.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_create_page.dart';
import '../../../../src/guest/guest_detail_page.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/invitation/invitation_api.dart';
import '../../../../src/invitation/invitation_providers.dart';
import '../../../../src/table/table_api.dart';
import '../../../../src/table/table_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import 'evenement_detail_screen.dart';

/// Filtres du rapport de présence.
enum GuestRsvpFilter { all, confirmed, pending, declined }

extension GuestRsvpFilterX on GuestRsvpFilter {
  String get label => switch (this) {
    GuestRsvpFilter.all => 'Tous',
    GuestRsvpFilter.confirmed => 'Confirmé',
    GuestRsvpFilter.pending => 'En attente',
    GuestRsvpFilter.declined => 'Décliné',
  };
}

/// Tri de la liste des invités.
enum GuestSort { tableThenName, nameAsc, status }

extension GuestSortX on GuestSort {
  String get label => switch (this) {
    GuestSort.tableThenName => 'Table & Ordre alphabétique',
    GuestSort.nameAsc => 'Ordre alphabétique',
    GuestSort.status => 'Statut RSVP',
  };
}

/// Gestion des invités d'un événement (espace organisateur).
///
/// Écran « Invités » : rapport de présence, filtres, recherche, tri,
/// sélection multiple, affectation de table et diffusion WhatsApp.
/// Uniquement les endpoints existants : `/api/events/{id}` + `guests`,
/// `invitations`, `assignments`, `dashboard`.
class GuestsManagementScreen extends ConsumerStatefulWidget {
  const GuestsManagementScreen({
    super.key,
    required this.weddingId,
    this.onBack,
  });

  final int weddingId;
  final VoidCallback? onBack;

  @override
  ConsumerState<GuestsManagementScreen> createState() =>
      _GuestsManagementScreenState();
}

class _GuestsManagementScreenState extends ConsumerState<GuestsManagementScreen> {
  bool _loading = true;
  String? _error;

  Wedding? _event;
  List<Guest> _guests = const [];
  List<Invitation> _invitations = const [];
  List<TableAssignment> _assignments = const [];
  Dashboard? _dashboard;

  GuestRsvpFilter _filter = GuestRsvpFilter.all;
  GuestSort _sort = GuestSort.tableThenName;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Set<int> _selected = <int>{};
  bool _busy = false;

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
      _selected.clear();
    });
    try {
      final weddingApi = ref.read(weddingApiProvider);
      final guestApi = ref.read(guestApiProvider);
      final invitationApi = ref.read(invitationApiProvider);
      final results = await Future.wait(<Future<Object>>[
        weddingApi.getById(widget.weddingId),
        guestApi.listGuests(widget.weddingId),
        invitationApi.list(widget.weddingId),
      ]);
      if (!mounted) return;
      setState(() {
        _event = results[0] as Wedding;
        _guests = results[1] as List<Guest>;
        _invitations = results[2] as List<Invitation>;
        _loading = false;
      });
      await _loadSideData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les invités';
      });
    }
  }

  /// Données annexes (dashboard, affectations de tables) : un échec ici ne
  /// bloque pas l'affichage de la liste.
  Future<void> _loadSideData() async {
    try {
      final dash =
          await ref.read(dashboardApiProvider).getForWedding(widget.weddingId);
      if (mounted) setState(() => _dashboard = dash);
    } catch (_) {
      // Statistiques optionnelles.
    }
    try {
      final items =
          await ref.read(tableApiProvider).listAllAssignments(widget.weddingId);
      if (mounted) setState(() => _assignments = items);
    } catch (_) {
      // Affectations optionnelles.
    }
  }

  Future<void> _refresh() async {
    await _load();
  }
  // --- Données dérivées ---------------------------------------------------

  Map<int, Invitation> get _invitationByGuestId => {
    for (final inv in _invitations) inv.guestId: inv,
  };

  Map<int, String> get _tableNameByGuestId => {
    for (final a in _assignments) a.guestId: a.tableName,
  };

  /// `ACCEPTED` / `DECLINED` / `PENDING`, ou `null` si aucune invitation.
  String? _rsvpOf(Guest guest) {
    final inv = _invitationByGuestId[guest.id];
    if (inv == null) return null;
    switch (inv.status.toUpperCase()) {
      case 'ACCEPTED':
      case 'CONFIRMED':
        return 'ACCEPTED';
      case 'DECLINED':
      case 'REFUSED':
        return 'DECLINED';
      case 'DRAFT':
      case 'CANCELLED':
      case 'CANCELED':
        return null;
      default:
        return 'PENDING';
    }
  }

  String? _tableOf(Guest guest) => _tableNameByGuestId[guest.id];

  int _countOf(GuestRsvpFilter filter) {
    if (filter == GuestRsvpFilter.all) return _guests.length;
    final wanted = switch (filter) {
      GuestRsvpFilter.confirmed => 'ACCEPTED',
      GuestRsvpFilter.pending => 'PENDING',
      GuestRsvpFilter.declined => 'DECLINED',
      GuestRsvpFilter.all => '',
    };
    return _guests.where((g) => _rsvpOf(g) == wanted).length;
  }

  int get _totalCount => _guests.length;
  int get _confirmedCount => _countOf(GuestRsvpFilter.confirmed);
  int get _pendingCount => _countOf(GuestRsvpFilter.pending);
  int get _declinedCount => _countOf(GuestRsvpFilter.declined);

  double get _confirmationRate =>
      _totalCount == 0 ? 0 : _confirmedCount / _totalCount;

  /// Invités sans table (issu du dashboard, sinon calculé localement).
  int get _unassignedCount {
    final dash = _dashboard;
    if (dash != null) return dash.guests.unassigned;
    return _guests.where((g) => _tableOf(g) == null).length;
  }

  /// Tables affectées (dashboard, sinon nombre de tables distinctes vues).
  int get _tablesCount {
    final dash = _dashboard;
    if (dash != null && dash.tables.total > 0) return dash.tables.total;
    return _assignments.map((a) => a.tableId).toSet().length;
  }

  /// Liste affichée : filtre RSVP + recherche + tri.
  List<Guest> get _visibleGuests {
    var list = _guests;
    if (_filter != GuestRsvpFilter.all) {
      final wanted = switch (_filter) {
        GuestRsvpFilter.confirmed => 'ACCEPTED',
        GuestRsvpFilter.pending => 'PENDING',
        GuestRsvpFilter.declined => 'DECLINED',
        GuestRsvpFilter.all => '',
      };
      list = list.where((g) => _rsvpOf(g) == wanted).toList();
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((g) {
        final name = g.displayName.toLowerCase();
        final phone = (g.phone ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }
    final sorted = List<Guest>.of(list);
    switch (_sort) {
      case GuestSort.nameAsc:
        sorted.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
        );
      case GuestSort.status:
        sorted.sort(
          (a, b) => (_rsvpOf(a) ?? 'ZZ').compareTo(_rsvpOf(b) ?? 'ZZ'),
        );
      case GuestSort.tableThenName:
        sorted.sort((a, b) {
          final tableA = (_tableOf(a) ?? 'zzz').toLowerCase();
          final tableB = (_tableOf(b) ?? 'zzz').toLowerCase();
          final byTable = tableA.compareTo(tableB);
          if (byTable != 0) return byTable;
          return a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
        });
    }
    return sorted;
  }
  // --- Actions ------------------------------------------------------------

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
      ),
    );
    if (created == true) await _refresh();
  }

  void _openGuest(Guest guest) {
    if (_selected.isNotEmpty) {
      _toggleSelection(guest.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GuestDetailPage(guest: guest)),
    );
  }

  void _toggleSelection(int guestId) {
    setState(() {
      if (!_selected.remove(guestId)) _selected.add(guestId);
    });
  }

  void _selectAllVisible() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_visibleGuests.map((g) => g.id));
    });
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(_selected.clear);
  }

  Future<void> _showSortSheet() async {
    final picked = await showModalBottomSheet<GuestSort>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sort in GuestSort.values)
              ListTile(
                leading: Icon(
                  sort == _sort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                title: Text(sort.label),
                onTap: () => Navigator.of(ctx).pop(sort),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _assignTable(Guest guest) async {
    try {
      final tables = await ref.read(tableApiProvider).list(widget.weddingId);
      if (!mounted) return;
      if (tables.isEmpty) {
        _toast('Aucune table pour cet événement');
        return;
      }
      final picked = await showModalBottomSheet<WeddingTable>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Assigner ${guest.displayName} à une table',
                  style: AppTypography.cardTitle(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              for (final table in tables)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.table_restaurant_outlined,
                      size: 20,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  title: Text(table.name),
                  subtitle: Text(
                    '${table.assignedCount}/${table.capacity} places · '
                    '${table.remainingCapacity} restante(s)',
                  ),
                  onTap: () => Navigator.of(ctx).pop(table),
                ),
            ],
          ),
        ),
      );
      if (picked == null || !mounted) return;
      await ref.read(tableApiProvider).assign(
            weddingId: widget.weddingId,
            tableId: picked.id,
            guestId: guest.id,
          );
      if (!mounted) return;
      _toast('${guest.displayName} → ${picked.name}');
      await _refresh();
    } catch (_) {
      if (mounted) _toast('Affectation impossible');
    }
  }

  /// Diffusion WhatsApp (`POST .../invitations/send-bulk`).
  ///
  /// Avec une sélection : uniquement les invités sélectionnés.
  /// Sans sélection : relance des invités sans réponse.
  Future<void> _broadcastWhatsApp() async {
    if (_busy) return;
    final selectedInvitationIds = _invitations
        .where((inv) => _selected.contains(inv.guestId))
        .map((inv) => inv.id)
        .toList();
    final onlyPending = selectedInvitationIds.isEmpty;
    setState(() => _busy = true);
    try {
      final batch = await ref.read(invitationApiProvider).startBulkSend(
            widget.weddingId,
            BulkSendRequest(
              invitationIds: selectedInvitationIds,
              resend: onlyPending,
              onlyPendingRsvp: onlyPending,
            ),
          );
      if (!mounted) return;
      _toast('Envoi WhatsApp lancé (${batch.totalCount} invitation(s))');
      _clearSelection();
    } catch (_) {
      if (mounted) _toast('Envoi WhatsApp impossible');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.guestCreate);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scheme, canCreate),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _buildBody(scheme),
              ),
            ),
            _buildStickyAction(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 40,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.warning_rounded, size: 56, color: scheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ],
      );
    }

    final guests = _visibleGuests;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.md),
        _buildEventHero(scheme),
        const SizedBox(height: AppSpacing.xxl),
        _buildPresenceSection(scheme),
        const SizedBox(height: AppSpacing.lg),
        _buildReminderBanner(scheme),
        const SizedBox(height: AppSpacing.lg),
        _buildSearchBar(scheme),
        const SizedBox(height: AppSpacing.lg),
        _buildFilterChips(scheme),
        const SizedBox(height: AppSpacing.xl),
        _buildListHeader(scheme),
        const SizedBox(height: AppSpacing.md),
        if (guests.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 56,
                  color: scheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun invité à afficher',
                  style: AppTypography.cardTitle(color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifiez la recherche ou le filtre, ou ajoutez un invité.',
                  textAlign: TextAlign.center,
                  style: AppTypography.small(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          for (final guest in guests)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: _buildGuestCard(scheme, guest),
            ),
      ],
    );
  }
  Widget _buildHeader(ColorScheme scheme, bool canCreate) {
    final typeLabel = _eventTypeLabel(_event?.type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Invités',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(color: scheme.onSurface)
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                Text(
                  '$typeLabel · $_totalCount invités',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small(color: scheme.onSurfaceVariant)
                      .copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _headerIconButton(
            scheme,
            icon: Icons.tune_rounded,
            onTap: _showOptionsSheet,
          ),
          const SizedBox(width: 6),
          _headerIconButton(
            scheme,
            icon: Icons.chat_rounded,
            color: OrganizerColors.whatsapp,
            onTap: _busy ? null : _broadcastWhatsApp,
          ),
          if (canCreate) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Inviter',
                      style: AppTypography.small(color: Colors.white).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerIconButton(
    ColorScheme scheme, {
    required IconData icon,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        child: Icon(icon, size: 18, color: color ?? scheme.onSurface),
      ),
    );
  }
  /// Carte événement (dégradé violet) : type, statut, couple, date et lieu.
  Widget _buildEventHero(ColorScheme scheme) {
    final event = _event;
    final status = (event?.status ?? '').toUpperCase();
    final statusColor = switch (status) {
      'ACTIVE' || 'PUBLISHED' => OrganizerColors.successOnDark,
      'DRAFT' => OrganizerColors.warningOnDark,
      _ => OrganizerColors.warningOnDark,
    };
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvenementDetailScreen(weddingId: widget.weddingId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            colors: [OrganizerColors.primaryDark, OrganizerColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: OrganizerColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _heroPill(
                        '${_eventTypeLabel(event?.type)} · SPÉCIAL',
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.18),
                      ),
                      const SizedBox(width: 6),
                      _heroPill(
                        _eventStatusLabel(status),
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.16),
                        dotColor: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    event?.displayName ?? 'Événement #${widget.weddingId}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _eventDateLine(event),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(
                        Icons.place_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _eventVenueLine(event),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPill(
    String label, {
    required Color color,
    required Color background,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
  /// Bloc « RAPPORT DE PRÉSENCE » : total, taux, sans table, tables, statuts.
  Widget _buildPresenceSection(ColorScheme scheme) {
    final rate = (_confirmationRate * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 17, color: scheme.secondary),
              const SizedBox(width: 6),
              Text(
                'RAPPORT DE PRÉSENCE',
                style: AppTypography.small(color: scheme.onSurfaceVariant)
                    .copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
              boxShadow: AppShadows.subtle(scheme.shadow),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_totalCount',
                          style: AppTypography.stat(color: scheme.onSurface)
                              .copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Invités',
                          style: AppTypography.body(
                            color: scheme.onSurfaceVariant,
                          ).copyWith(fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _PresencePill(
                                label: '$rate% confirmés',
                                color: OrganizerColors.success,
                                background: OrganizerColors.successBg,
                                icon: Icons.trending_up_rounded,
                              ),
                              _PresencePill(
                                label: '+$_unassignedCount',
                                color: OrganizerColors.warning,
                                background: OrganizerColors.warningBg,
                                icon: Icons.table_restaurant_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_tablesCount tables ont été assignées',
                            textAlign: TextAlign.end,
                            style: AppTypography.small(
                              color: scheme.onSurfaceVariant,
                            ).copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(
                  height: 1,
                  color: scheme.outline.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _CountChip(
                      label: 'Confirmés',
                      value: _confirmedCount,
                      color: OrganizerColors.success,
                      background: OrganizerColors.successBg,
                    ),
                    _CountChip(
                      label: 'En attente',
                      value: _pendingCount,
                      color: OrganizerColors.warning,
                      background: OrganizerColors.warningBg,
                    ),
                    _CountChip(
                      label: 'Déclinés',
                      value: _declinedCount,
                      color: OrganizerColors.danger,
                      background: OrganizerColors.dangerBg,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// Bannière « Relancer N invités par WhatsApp/SMS ».
  Widget _buildReminderBanner(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: _busy ? null : _broadcastWhatsApp,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Relancer $_pendingCount invités par WhatsApp/SMS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small(color: scheme.onSurface).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHighest
                    : OrganizerColors.fieldFill,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(
                  color: scheme.onSurface,
                ).copyWith(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, table, tél...',
                  hintStyle: AppTypography.body(
                    color: scheme.onSurfaceVariant,
                  ).copyWith(fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: _showOptionsSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.45),
                ),
                boxShadow: AppShadows.subtle(scheme.shadow, blur: 10),
              ),
              child: Icon(Icons.tune_rounded, size: 20, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChips(ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          for (final filter in GuestRsvpFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Builder(
                builder: (_) {
                  final selected = _filter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            filter.label,
                            style: AppTypography.small(
                              color: selected ? Colors.white : scheme.onSurface,
                            ).copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_countOf(filter)}',
                            style: AppTypography.small(
                              color: selected
                                  ? Colors.white
                                  : scheme.onSurfaceVariant,
                            ).copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListHeader(ColorScheme scheme) {
    final selectionActive = _selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showSortSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Trier : ${_sort.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.small(color: scheme.primary)
                          .copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: selectionActive ? _clearSelection : _selectAllVisible,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                selectionActive ? 'Tout désélectionner' : 'Sélectionner tout',
                style: AppTypography.small(color: scheme.primary).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Carte invité : avatar coloré, nom + catégorie, contacts, table, statut.
  Widget _buildGuestCard(ColorScheme scheme, Guest guest) {
    final style = _statusStyle(_rsvpOf(guest));
    final table = _tableOf(guest);
    final selected = _selected.contains(guest.id);
    final category = _categoryNameOf(guest);
    final companions = guest.allowedCompanions ?? 0;
    final phone = guest.phone ?? '';

    return GestureDetector(
      onTap: () => _openGuest(guest),
      onLongPress: () => _toggleSelection(guest.id),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.5),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: AppShadows.subtle(scheme.shadow),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selected.isNotEmpty) ...[
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected ? scheme.primary : scheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  _GuestAvatar(
                    name: guest.displayName,
                    color: style.color,
                    background: style.background,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                guest.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle(
                                  color: scheme.onSurface,
                                ).copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (category != null && category.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• $category',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: OrganizerColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _infoRow(scheme, Icons.phone_outlined, phone),
                        ],
                        if (companions > 0) ...[
                          const SizedBox(height: 4),
                          _infoRow(
                            scheme,
                            Icons.people_outline_rounded,
                            '+$companions accompagnant(s)',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (table != null)
                    Flexible(child: _tablePill(scheme, table))
                  else
                    GestureDetector(
                      onTap: () => _assignTable(guest),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Assigner une table',
                            style: AppTypography.small(color: scheme.primary)
                                .copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  _StatusBadge(style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _infoRow(ColorScheme scheme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small(
              color: scheme.onSurfaceVariant,
            ).copyWith(fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  Widget _tablePill(ColorScheme scheme, String table) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 12,
            color: scheme.primary,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              table,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.small(color: scheme.primary).copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Catégorie de l'invité (badge « VIP », « Famille »...) via le dashboard.
  String? _categoryNameOf(Guest guest) {
    final id = guest.categoryId;
    if (id == null) return null;
    for (final category in _dashboard?.categories ?? const <CategoryStats>[]) {
      if (category.categoryId == id) return category.name;
    }
    return null;
  }

  _StatusStyle _statusStyle(String? rsvp) {
    switch (rsvp) {
      case 'ACCEPTED':
        return const _StatusStyle(
          label: 'Confirmé',
          color: OrganizerColors.success,
          background: OrganizerColors.successBg,
          icon: Icons.check_rounded,
        );
      case 'DECLINED':
        return const _StatusStyle(
          label: 'Décliné',
          color: OrganizerColors.danger,
          background: OrganizerColors.dangerBg,
          icon: Icons.close_rounded,
        );
      case 'PENDING':
        return const _StatusStyle(
          label: 'En attente',
          color: OrganizerColors.warning,
          background: OrganizerColors.warningBg,
          icon: Icons.hourglass_top_rounded,
        );
      default:
        return const _StatusStyle(
          label: 'Non invité',
          color: OrganizerColors.muted,
          background: OrganizerColors.mutedBg,
          icon: Icons.person_off_outlined,
        );
    }
  }
  /// Barre d'action collante en bas : diffusion WhatsApp.
  Widget _buildStickyAction(ColorScheme scheme) {
    final selectionActive = _selected.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            selectionActive ? Icons.checklist_rounded : Icons.campaign_outlined,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              selectionActive
                  ? '${_selected.length} invité(s) sélectionné(s)'
                  : 'Diffuser une mise à jour aux invités',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.small(color: scheme.onSurface).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _busy ? null : _broadcastWhatsApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OrganizerColors.whatsapp,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chat_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'WhatsApp',
                    style: AppTypography.small(color: Colors.white).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Feuille « Filtres + Trier par » (bouton réglages).
  Future<void> _showOptionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sheetScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'Filtres',
                    style: AppTypography.cardTitle(color: sheetScheme.onSurface),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final filter in GuestRsvpFilter.values)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() => _filter = filter);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _filter == filter
                                  ? sheetScheme.primary
                                  : sheetScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _filter == filter
                                    ? sheetScheme.primary
                                    : sheetScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${filter.label} (${_countOf(filter)})',
                              style: AppTypography.small(
                                color: _filter == filter
                                    ? Colors.white
                                    : sheetScheme.onSurface,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'Trier par',
                    style: AppTypography.cardTitle(color: sheetScheme.onSurface),
                  ),
                ),
                for (final sort in GuestSort.values)
                  ListTile(
                    leading: Icon(
                      sort == _sort
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: sheetScheme.primary,
                    ),
                    title: Text(sort.label),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _sort = sort);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Libellé du type d'événement (`MARIAGE`, `ANNIVERSAIRE`, ...).
String _eventTypeLabel(String? type) => switch ((type ?? '').toUpperCase()) {
  'WEDDING' => 'MARIAGE',
  'COLLATION' => 'COLLATION',
  'ANNIVERSARY' => 'ANNIVERSAIRE',
  'BAPTISM' => 'BAPTÊME',
  'GRADUATION' => 'DIPLÔME',
  _ => 'ÉVÉNEMENT',
};

String _eventStatusLabel(String status) => switch (status) {
  'ACTIVE' || 'PUBLISHED' => 'Confirmé',
  'DRAFT' => 'Brouillon',
  'COMPLETED' => 'Terminé',
  'CANCELLED' => 'Annulé',
  _ => 'À venir',
};

/// « Samedi 28 Juin 2025 · 15h00 » (sans dépendance `intl`).
String _eventDateLine(Wedding? event) {
  if (event == null) return 'Date à définir';
  final date = _frenchDate(event.eventDate);
  final time = _frenchTime(event.startTime);
  final parts = <String>[?date, ?time];
  if (parts.isEmpty) return 'Date à définir';
  return parts.join(' · ');
}

String _eventVenueLine(Wedding? event) {
  if (event == null) return 'Lieu à définir';
  final venue = event.venueName?.trim() ?? '';
  final city = event.city?.trim() ?? '';
  if (venue.isNotEmpty && city.isNotEmpty) return '$venue · $city';
  if (venue.isNotEmpty) return venue;
  if (city.isNotEmpty) return city;
  return 'Lieu à définir';
}

/// « 2025-06-28 » → « Samedi 28 Juin 2025 ».
String? _frenchDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const days = <String>[
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  const months = <String>[
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  return '${days[parsed.weekday - 1]} ${parsed.day} '
      '${months[parsed.month - 1]} ${parsed.year}';
}

/// « 15:00:00 » → « 15h00 ».
String? _frenchTime(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return '${hour.toString().padLeft(2, '0')}h'
      '${minute.toString().padLeft(2, '0')}';
}
/// Avatar rond avec initiales, coloré selon le statut RSVP.
class _GuestAvatar extends StatelessWidget {
  const _GuestAvatar({
    required this.name,
    required this.color,
    required this.background,
  });

  final String name;
  final Color color;
  final Color background;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) continue;
      buffer.write(part[0].toUpperCase());
      if (buffer.length == 2) break;
    }
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Badge de statut (« ✓ Confirmé », « En attente », « Non invité »).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
/// Pastille du rapport de présence (taux de confirmation, sans table).
class _PresencePill extends StatelessWidget {
  const _PresencePill({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit compteur « ● Confirmés 29 ».
class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Style d'un statut RSVP (libellé, couleurs, icône).
class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;
}
