import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_detail_page.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/app_organizer_bottom_nav.dart';
import 'evenement_create_stepper_screen.dart';
import 'evenement_detail_screen.dart';

enum EventStatusFilter { all, upcoming, active, past, draft }

extension EventStatusFilterLabel on EventStatusFilter {
  String get label => switch (this) {
    EventStatusFilter.all => 'Tous',
    EventStatusFilter.upcoming => 'À venir',
    EventStatusFilter.active => 'En cours',
    EventStatusFilter.past => 'Passés',
    EventStatusFilter.draft => 'Brouillons',
  };
}

class MesEvenementsScreen extends ConsumerStatefulWidget {
  const MesEvenementsScreen({super.key, this.embedded = false});

  /// Quand `true`, l'écran est intégré comme onglet (ex. Accueil) dans un
  /// Scaffold parent qui fournit déjà la barre de navigation et le FAB.
  /// On retire alors sa propre bottom nav, son FAB et son bouton retour.
  final bool embedded;

  @override
  ConsumerState<MesEvenementsScreen> createState() =>
      _MesEvenementsScreenState();
}

class _MesEvenementsScreenState extends ConsumerState<MesEvenementsScreen> {
  bool _loading = true;
  String? _error;
  List<Wedding> _events = const [];
  EventStatusFilter _filter = EventStatusFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      final items = await ref.read(weddingApiProvider).list(size: 50);
      if (!mounted) return;
      setState(() {
        _events = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les événements';
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  List<Wedding> get _filteredEvents {
    var list = _events;
    if (_filter != EventStatusFilter.all) {
      list = list.where((e) => _matchesFilter(e)).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((e) {
      final name = e.displayName.toLowerCase();
      final venue = '${e.groomFirstName} ${e.brideFirstName}'.toLowerCase();
      return name.contains(q) || venue.contains(q);
    }).toList();
  }

  bool _matchesFilter(Wedding e) {
    final status = e.status.toUpperCase();
    switch (_filter) {
      case EventStatusFilter.active:
        return status == 'ACTIVE' || status == 'PUBLISHED';
      case EventStatusFilter.draft:
        return status == 'DRAFT';
      case EventStatusFilter.past:
        return false;
      case EventStatusFilter.upcoming:
        return status != 'ACTIVE' && status != 'PUBLISHED' && status != 'DRAFT';
      case EventStatusFilter.all:
        return true;
    }
  }

  int get _totalCount => _events.length;
  int get _activeCount => _events
      .where(
        (e) =>
            e.status.toUpperCase() == 'ACTIVE' ||
            e.status.toUpperCase() == 'PUBLISHED',
      )
      .length;
  int get _upcomingCount => _events.where((e) {
    final s = e.status.toUpperCase();
    return s != 'ACTIVE' && s != 'PUBLISHED' && s != 'DRAFT';
  }).length;
  int get _pastCount => 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(weddingListRevisionProvider, (previous, next) {
      if (previous != next) _load();
    });
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.weddingCreate);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Fond blanc de la maquette (les cartes se détachent par leur ombre).
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scheme, canCreate),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildSearchBar(scheme),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFilterChips(scheme),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStatsCard(scheme),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildListHeader(scheme),
                      const SizedBox(height: AppSpacing.lg),
                      if (_loading)
                        _buildSkeleton(scheme)
                      else if (_error != null)
                        _buildError(scheme)
                      else if (_filteredEvents.isEmpty &&
                          _searchQuery.trim().isEmpty)
                        _buildEmpty(scheme, canCreate)
                      else if (_filteredEvents.isEmpty)
                        _buildNoResults(scheme)
                      else
                        _buildEventList(scheme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : AppOrganizerBottomNav(
              current: OrganizerTab.home,
              onSelect: (tab) {
                if (tab == OrganizerTab.add) {
                  _openCreate();
                  return;
                }
              },
            ),
      floatingActionButton: widget.embedded
          ? null
          : canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [OrganizerColors.primaryDark, OrganizerColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OrganizerColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(ColorScheme scheme, bool canCreate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              // Pill « ESPACE ORGANISATEUR ».
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ESPACE ORGANISATEUR',
                      style: AppTypography.small(color: scheme.primary).copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (canCreate) _buildHeaderAction(scheme),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mes événements',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(color: scheme.onSurface).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton « + » arrondi de l'en-tête (création d'un événement).
  Widget _buildHeaderAction(ColorScheme scheme) {
    return GestureDetector(
      onTap: _openCreate,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
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
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHighest
                    : OrganizerColors.fieldFill,
                borderRadius: BorderRadius.circular(26),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Rechercher un événement…',
                  hintStyle: AppTypography.body(color: scheme.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22,
                    color: scheme.onSurfaceVariant,
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
          _buildFilterButton(scheme),
        ],
      ),
    );
  }

  /// Bouton filtre / tri, à droite du champ de recherche.
  Widget _buildFilterButton(ColorScheme scheme) {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
          boxShadow: AppShadows.subtle(scheme.shadow, blur: 10),
        ),
        child: Icon(Icons.tune_rounded, size: 22, color: scheme.onSurface),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: EventStatusFilter.values.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        f.label,
                        style: AppTypography.small(
                          color: selected ? Colors.white : scheme.onSurface,
                        ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.subtle(scheme.shadow),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.grid_view_rounded,
              iconBg: scheme.primary.withValues(alpha: 0.12),
              iconColor: scheme.primary,
              value: '$_totalCount',
              label: 'Total',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.verified_user_outlined,
              iconBg: OrganizerColors.successBg,
              iconColor: OrganizerColors.success,
              value: '$_activeCount',
              label: 'En cours',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.schedule_rounded,
              iconBg: OrganizerColors.warningBg,
              iconColor: OrganizerColors.warning,
              value: '$_upcomingCount',
              label: 'À venir',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.inventory_2_outlined,
              iconBg: OrganizerColors.infoBg,
              iconColor: OrganizerColors.info,
              value: '$_pastCount',
              label: 'Passés',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Liste des événements',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sectionTitle(color: scheme.onSurface)
                  .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surfaceContainerHighest
                  : OrganizerColors.fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_filteredEvents.length}',
              style: AppTypography.small(color: scheme.onSurfaceVariant)
                  .copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: Icon(Icons.sort_rounded, size: 18, color: scheme.primary),
            label: Text(
              'Trier',
              style: AppTypography.small(color: scheme.primary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme scheme) {
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Shimmer(
              width: double.infinity,
              height: 160,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: scheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Erreur',
              style: AppTypography.cardTitle(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme scheme, bool canCreate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: scheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement pour le moment',
              style: AppTypography.cardTitle(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par créer votre premier événement.',
              style: AppTypography.body(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (canCreate) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [OrganizerColors.primaryDark, OrganizerColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openCreate,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Créer mon premier événement',
                        style: AppTypography.button(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement ne correspond à votre recherche',
              style: AppTypography.body(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(ColorScheme scheme) {
    final filtered = _filteredEvents;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: filtered.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final e = filtered[index];
        return _EventCard(
          event: e,
          onTap: () => _openDetail(e.id),
          onMenu: () => _showMenu(e),
        );
      },
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EvenementCreateStepperScreen()),
    );
    if (created == true) await _load();
  }

  Future<void> _openDetail(int id) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EvenementDetailScreen(weddingId: id)),
    );
    if (changed == true) await _load();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.access_time_rounded),
              title: Text('Plus récent'),
            ),
            const ListTile(
              leading: Icon(Icons.history_rounded),
              title: Text('Plus ancien'),
            ),
            const ListTile(
              leading: Icon(Icons.event_rounded),
              title: Text('Date de début'),
            ),
            const ListTile(
              leading: Icon(Icons.sort_by_alpha_rounded),
              title: Text('Nom A-Z'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(Wedding e) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Voir'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openDetail(e.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => WeddingDetailPage(weddingId: e.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Changer le statut'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: AppTypography.stat(color: scheme.onSurface)
              .copyWith(fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.small(color: scheme.onSurfaceVariant)
              .copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onMenu,
  });

  final Wedding event;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final status = event.status.toUpperCase();
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.eventCard),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          boxShadow: AppShadows.subtle(scheme.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EventCover(type: event.type),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusPill(
                            label: _eventTypeLabel(event.type),
                            color: _eventTypeColor(event.type),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _StatusPill(
                              label: _statusLabel(status),
                              color: statusColor,
                              showDot: true,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onMenu,
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(28, 28),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(color: scheme.onSurface)
                            .copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _MetaLine(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDate(event),
                      ),
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: Icons.location_on_outlined,
                        text: _placeLine(event),
                      ),
                      // Le compteur d'invités est désormais dans le pied de carte
                      // (`_ProgressFooter`) : plus de ligne « 0 invités » statique.
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProgressFooter(eventId: event.id),
          ],
        ),
      ),
    );
  }
}

/// Ligne date + heure : « Samedi 28 Juin 2025 • 15h00 ».
String _formatDate(Wedding e) {
  final date = _frenchDate(e.eventDate);
  final time = _frenchTime(e.startTime);
  final parts = <String>[?date, ?time];
  if (parts.isEmpty) return 'Date à définir';
  return parts.join(' • ');
}

/// Ligne du lieu : « Hôtel Pullman • Kinshasa », repli sur l'organisation.
String _placeLine(Wedding e) {
  final venue = e.venueName?.trim() ?? '';
  final city = e.city?.trim() ?? '';
  if (venue.isNotEmpty && city.isNotEmpty) return '$venue • $city';
  if (venue.isNotEmpty) return 'Organisation #${e.organizationId} • $venue';
  if (city.isNotEmpty) return 'Organisation #${e.organizationId} • $city';
  return 'Organisation #${e.organizationId}';
}

/// « 2025-06-28 » → « Samedi 28 Juin 2025 » (sans dépendance `intl`).
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
  final day = days[parsed.weekday - 1];
  final month = months[parsed.month - 1];
  return '$day ${parsed.day} $month ${parsed.year}';
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

String _statusLabel(String status) => switch (status) {
  'ACTIVE' || 'PUBLISHED' => 'En cours',
  'DRAFT' => 'Brouillon',
  _ => 'À venir',
};

Color _statusColor(String status) => switch (status) {
  'ACTIVE' || 'PUBLISHED' => OrganizerColors.success,
  'DRAFT' => OrganizerColors.primary,
  _ => OrganizerColors.warning,
};

/// Libellé court du type d'événement (badge + pastille de vignette).
String _eventTypeLabel(String type) => switch (type.toUpperCase()) {
  'WEDDING' => 'MARIAGE',
  'COLLATION' => 'COLLATION',
  'ANNIVERSARY' => 'ANNIVERSAIRE',
  'BAPTISM' => 'BAPTÊME',
  'GRADUATION' => 'DIPLÔME',
  _ => 'ÉVÉNEMENT',
};

Color _eventTypeColor(String type) => switch (type.toUpperCase()) {
  'WEDDING' => OrganizerColors.primary,
  'ANNIVERSARY' => OrganizerColors.accent,
  'COLLATION' => OrganizerColors.info,
  'BAPTISM' => OrganizerColors.info,
  'GRADUATION' => OrganizerColors.info,
  _ => OrganizerColors.info,
};

/// Dégradé de la vignette selon le type (lavande/rose, bleu ciel sinon).
List<Color> _eventTypeGradient(String type) => switch (type.toUpperCase()) {
  'WEDDING' => const [
    OrganizerColors.lightSurfaceViolet,
    OrganizerColors.accentBg,
  ],
  'ANNIVERSARY' => const [
    OrganizerColors.accentBg,
    OrganizerColors.lightSurfaceViolet,
  ],
  _ => const [OrganizerColors.infoBg, OrganizerColors.lightSurfaceViolet],
};

IconData _eventTypeIcon(String type) => switch (type.toUpperCase()) {
  'BAPTISM' => Icons.child_care_rounded,
  'GRADUATION' => Icons.school_rounded,
  'ANNIVERSARY' => Icons.cake_rounded,
  'COLLATION' => Icons.restaurant_rounded,
  _ => Icons.apartment_rounded,
};

/// Pastille compacte (type d'événement, statut), avec point optionnel.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne méta d'une carte (petite icône + texte sur une seule ligne).
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small(color: scheme.onSurfaceVariant)
                .copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

/// Vignette carrée de l'événement (dégradé + pictogramme + libellé de type).
class _EventCover extends StatelessWidget {
  const _EventCover({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(type);
    final isWedding = type.toUpperCase() == 'WEDDING';
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _eventTypeGradient(type),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: isWedding
                  ? const Text('🎉', style: TextStyle(fontSize: 32))
                  : Icon(_eventTypeIcon(type), size: 30, color: color),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _eventTypeLabel(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pied de carte : « 142 / 200 confirmés » + barre de progression.
///
/// Les chiffres proviennent du dashboard déjà existant
/// (`GET /api/events/{id}/dashboard`), mis en cache par identifiant
/// d'événement. En cas d'échec réseau, la carte reste lisible (libellé neutre).
class _ProgressFooter extends ConsumerWidget {
  const _ProgressFooter({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stats = ref.watch(eventDashboardProvider(eventId));
    final data = stats.valueOrNull;
    final confirmed = data?.invitations.accepted ?? 0;
    final total = data?.guests.total ?? 0;
    final ratio = total <= 0 ? 0.0 : (confirmed / total).clamp(0.0, 1.0);

    return Row(
      children: [
        Flexible(
          child: data == null
              ? Text(
                  stats.hasError
                      ? 'Statistiques indisponibles'
                      : 'Chargement…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small(color: scheme.onSurfaceVariant)
                      .copyWith(fontSize: 11.5),
                )
              : RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style:
                        AppTypography.small(color: scheme.onSurfaceVariant)
                            .copyWith(fontSize: 11.5),
                    children: [
                      TextSpan(
                        text: '$confirmed',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      TextSpan(text: ' / $total confirmés'),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: _ProgressBar(fraction: ratio, scheme: scheme)),
      ],
    );
  }
}

/// Barre de progression arrondie (piste neutre + remplissage violet).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction, required this.scheme});

  final double fraction;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: scheme.outline.withValues(alpha: 0.35),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
  });

  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        final shimmer = (value * 2) % 2 - 1;
        final opacity = 0.3 + (shimmer.abs() * 0.4);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }
}
