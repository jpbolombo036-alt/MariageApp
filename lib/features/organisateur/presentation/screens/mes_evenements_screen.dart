import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
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
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.weddingCreate);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                    colors: [Color(0xFF4E249E), Color(0xFF6B38D0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B38D0).withValues(alpha: 0.35),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                widget.embedded ? () {} : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.menu, size: 24),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes événements',
                  style: AppTypography.cardTitle(
                    color: scheme.onSurface,
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Organisateur',
                  style: AppTypography.small(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (canCreate)
            Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E249E), Color(0xFF6B38D0)],
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
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Nouvel événement',
                          style: AppTypography.small(
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTypography.body(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Rechercher un événement...',
                  hintStyle: AppTypography.body(color: scheme.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              onPressed: _showSortOptions,
              icon: Icon(Icons.sort_rounded, size: 22, color: scheme.onSurface),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
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
              child: FilterChip(
                label: Text(f.label),
                selected: selected,
                onSelected: (v) {
                  if (v) setState(() => _filter = f);
                },
                backgroundColor: scheme.surfaceContainerHighest,
                selectedColor: scheme.primary,
                labelStyle: AppTypography.small(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected
                        ? scheme.primary
                        : scheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                labelPadding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_today_outlined,
              iconBg: scheme.primaryContainer,
              iconColor: scheme.primary,
              value: '$_totalCount',
              label: 'Total',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.verified_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF22C55E),
              value: '$_activeCount',
              label: 'En cours',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.schedule_outlined,
              iconBg: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFF59E0B),
              value: '$_upcomingCount',
              label: 'À venir',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.archive_outlined,
              iconBg: scheme.surfaceContainerHighest,
              iconColor: scheme.onSurfaceVariant,
              value: '$_pastCount',
              label: 'Passés',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Liste des événements',
            style: AppTypography.sectionTitle(color: scheme.onSurface),
          ),
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: Icon(Icons.sort_rounded, size: 18, color: scheme.primary),
            label: Text(
              'Trier',
              style: AppTypography.small(color: scheme.primary),
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
                    colors: [Color(0xFF4E249E), Color(0xFF6B38D0)],
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

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EvenementCreateStepperScreen()),
    );
  }

  void _openDetail(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EvenementDetailScreen(weddingId: id)),
    );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modification bientôt disponible'),
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
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: AppTypography.stat(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.small(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onMenu,
  });

  final Wedding event;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = event.status.toUpperCase();
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      scheme.primaryContainer.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 38)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ÉVÉNEMENT',
                              style: AppTypography.small(
                                color: scheme.onPrimaryContainer,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Spacer(),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.small(color: statusColor)
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.5,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
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
                      const SizedBox(height: 6),
                      Text(
                        event.displayName,
                        style: AppTypography.cardTitle(
                          color: scheme.onSurface,
                        ).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(event),
                              style: AppTypography.small(
                                color: scheme.onSurfaceVariant,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Organisation #${event.organizationId}',
                              style: AppTypography.small(
                                color: scheme.onSurfaceVariant,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '0 invités',
                              style: AppTypography.small(
                                color: scheme.onSurfaceVariant,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(Wedding e) {
    final parts = <String>[
      if (e.groomFirstName.isNotEmpty) e.groomFirstName,
      if (e.brideFirstName.isNotEmpty) e.brideFirstName,
    ];
    return parts.join(' & ');
  }

  String _statusLabel(String status) => switch (status) {
    'ACTIVE' || 'PUBLISHED' => 'En cours',
    'DRAFT' => 'Brouillon',
    _ => 'À venir',
  };

  Color _statusColor(String status) => switch (status) {
    'ACTIVE' || 'PUBLISHED' => const Color(0xFF22C55E),
    'DRAFT' => OrganizerColors.primary,
    _ => const Color(0xFFF59E0B),
  };
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
