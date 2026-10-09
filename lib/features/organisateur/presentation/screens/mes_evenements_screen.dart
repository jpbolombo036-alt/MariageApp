// Accueil organisateur - reproduction de la maquette Accueil_organisateur
// (theme nuit premium, fond #0A0A1F, degards violets). Logique inchangee :
// chargement evenements + couvertures, filtres, recherche, tri, revision.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../src/auth/auth_models.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/app_organizer_bottom_nav.dart';
import 'evenement_create_stepper_screen.dart';
import 'evenement_detail_screen.dart';

/// Palette de la maquette (nuit violet).
abstract final class HomePalette {
  static const bg = Color(0xFF0A0A1F);
  static const card = Color(0xFF12122A);
  static const tile = Color(0xFF191933);
  static const chip = Color(0xFF15152E);
  static const border = Color(0x14FFFFFF); // blanc ~8 %
  static const purple = Color(0xFF8B5CF6);
  static const purpleDeep = Color(0xFF6D28D9);
  static const purpleLight = Color(0xFFA78BFA);
  static const text = Color(0xFFF4F4FA);
  static const text2 = Color(0xFF9A9AB5);
  static const text3 = Color(0xFF6E6E8C);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF3B82F6);
  static const red = Color(0xFFEF4444);

  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF9061F9), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

enum EventStatusFilter { all, upcoming, active, past, draft }

extension EventStatusFilterLabel on EventStatusFilter {
  String get label => switch (this) {
    EventStatusFilter.all => 'Tous',
    EventStatusFilter.upcoming => 'Ã€ venir',
    EventStatusFilter.active => 'En cours',
    EventStatusFilter.past => 'PassÃ©s',
    EventStatusFilter.draft => 'Brouillons',
  };
}

class MesEvenementsScreen extends ConsumerStatefulWidget {
  const MesEvenementsScreen({super.key, this.embedded = false});

  /// Quand `true`, l'Ã©cran est intÃ©grÃ© comme onglet (Accueil) : on retire la
  /// barre de navigation propre Ã  cet Ã©cran (celle du parent suffit).
  final bool embedded;

  @override
  ConsumerState<MesEvenementsScreen> createState() => _MesEvenementsScreenState();
}

class _MesEvenementsScreenState extends ConsumerState<MesEvenementsScreen> {
  bool _loading = true;
  String? _error;
  List<Wedding> _events = const [];
  EventStatusFilter _filter = EventStatusFilter.active;
  bool _sortDateDesc = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<int, Uint8List?> _coverImages = const {};

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
      final images = <int, Uint8List?>{};
      for (final e in items) {
        try {
          images[e.id] = await ref.read(weddingApiProvider).loadImage(e.id);
        } catch (_) {
          images[e.id] = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _coverImages = Map<int, Uint8List?>.unmodifiable(images);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les Ã©vÃ©nements';
      });
    }
  }
  /// Un Ã©vÃ©nement est Â« passÃ© Â» s'il est terminÃ©/archivÃ© ou datÃ© d'hier.
  bool _isPast(Wedding e) {
    final s = e.status.toUpperCase();
    if (s == 'COMPLETED' || s == 'ARCHIVED') return true;
    if (s == 'CANCELLED') return false;
    final raw = e.eventDate;
    if (raw == null || raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(parsed.year, parsed.month, parsed.day).isBefore(today);
  }

  bool _matchesFilter(Wedding e) {
    final status = e.status.toUpperCase();
    switch (_filter) {
      case EventStatusFilter.active:
        return status == 'ACTIVE' || status == 'PUBLISHED';
      case EventStatusFilter.draft:
        return status == 'DRAFT';
      case EventStatusFilter.past:
        return _isPast(e);
      case EventStatusFilter.upcoming:
        return !_isPast(e) &&
            status != 'ACTIVE' &&
            status != 'PUBLISHED' &&
            status != 'DRAFT';
      case EventStatusFilter.all:
        return true;
    }
  }

  List<Wedding> get _filteredEvents {
    final list = _events.where(_matchesFilter).toList();
    final q = _searchQuery.trim().toLowerCase();
    final searched = q.isEmpty
        ? list
        : list.where((e) {
            final name = e.displayName.toLowerCase();
            final couple =
                '${e.groomFirstName} ${e.brideFirstName}'.toLowerCase();
            final place = '${e.venueName ?? ''} ${e.city ?? ''}'.toLowerCase();
            return name.contains(q) || couple.contains(q) || place.contains(q);
          }).toList();
    searched.sort((a, b) {
      final da = DateTime.tryParse(a.eventDate ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b.eventDate ?? '') ?? DateTime(2000);
      return _sortDateDesc ? db.compareTo(da) : da.compareTo(db);
    });
    return searched;
  }

  int get _totalCount => _events.length;
  int get _activeCount => _events
      .where((e) {
        final s = e.status.toUpperCase();
        return s == 'ACTIVE' || s == 'PUBLISHED';
      })
      .length;
  int get _pastCount => _events.where(_isPast).length;
  int get _upcomingCount => _events.where((e) {
        final s = e.status.toUpperCase();
        return !_isPast(e) &&
            s != 'ACTIVE' &&
            s != 'PUBLISHED' &&
            s != 'DRAFT';
      }).length;

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EvenementCreateStepperScreen()),
    );
    if (created == true) {
      ref.read(weddingListRevisionProvider.notifier).bump();
      await _load();
    }
  }

  void _openDetail(Wedding e) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EvenementDetailScreen(weddingId: e.id)),
    );
  }
  @override
  Widget build(BuildContext context) {
    ref.listen<int>(weddingListRevisionProvider, (previous, next) {
      if (previous != next) _load();
    });
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.weddingCreate);

    return Scaffold(
      backgroundColor: HomePalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: HomePalette.purple,
                backgroundColor: HomePalette.card,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(auth.user?.firstName ?? ''),
                      _buildGreeting(auth.user?.firstName),
                      const SizedBox(height: 18),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 18),
                      _buildOverviewCard(),
                      const SizedBox(height: 22),
                      _buildListHeader(),
                      const SizedBox(height: 14),
                      if (_loading)
                        _buildSkeleton()
                      else if (_error != null)
                        _buildError()
                      else if (_filteredEvents.isEmpty &&
                          _searchQuery.trim().isEmpty)
                        _buildEmpty(canCreate)
                      else if (_filteredEvents.isEmpty)
                        _buildNoResults()
                      else
                        _buildEventList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            gradient: HomePalette.purpleGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x667C3AED),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : AppOrganizerBottomNav(
              current: OrganizerTab.home,
              onSelect: (tab) {
                if (tab == OrganizerTab.add) {
                  _openCreate();
                }
              },
            ),
    );
  }

  // ---------------------------------------------------------------- header --
  Widget _buildHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: HomePalette.purpleGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x557C3AED),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child:
                const Icon(Icons.event_available_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: HomePalette.text,
                      letterSpacing: -0.3,
                    ),
                    children: const [
                      TextSpan(text: 'Eventia'),
                      TextSpan(
                        text: 'Easy',
                        style: TextStyle(color: HomePalette.purpleLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'CrÃ©ez â€¢ Invitez â€¢ Partagez',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: HomePalette.text3,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: HomePalette.text2, size: 27),
              Positioned(
                top: 2,
                right: 3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: HomePalette.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: HomePalette.purpleLight, width: 2),
              gradient: HomePalette.purpleGradient,
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'O',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // -------------------------------------------------------------- greeting --
  Widget _buildGreeting(String? firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: HomePalette.text2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${firstName ?? 'Organisateur'} ðŸ‘‹',
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: HomePalette.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vos Ã©vÃ©nements, en toute simplicitÃ©',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: HomePalette.text3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Transform.rotate(
              angle: -0.09,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Des moments\nqui comptent !',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.greatVibes(
                      fontSize: 21,
                      height: 1.05,
                      color: HomePalette.purpleLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CustomPaint(
                    size: const Size(96, 8),
                    painter: _SwooshPainter(HomePalette.purple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------------------------- search --
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: HomePalette.chip,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomePalette.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded, color: HomePalette.text3, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: HomePalette.text,
                ),
                cursorColor: HomePalette.purple,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Rechercher un Ã©vÃ©nement...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: HomePalette.text3,
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: HomePalette.text3),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HomePalette.purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: HomePalette.purpleLight, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- chips --
  Widget _buildFilterChips() {
    const filters = [
      EventStatusFilter.all,
      EventStatusFilter.upcoming,
      EventStatusFilter.active,
      EventStatusFilter.past,
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: selected ? HomePalette.purpleGradient : null,
                color: selected ? null : HomePalette.chip,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? Colors.transparent : HomePalette.border,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x557C3AED),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ] else if (f == EventStatusFilter.upcoming) ...[
                    const Icon(Icons.event_rounded,
                        size: 15, color: HomePalette.text2),
                    const SizedBox(width: 6),
                  ] else if (f == EventStatusFilter.past) ...[
                    const Icon(Icons.schedule_rounded,
                        size: 15, color: HomePalette.text2),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    f.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : HomePalette.text2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // ------------------------------------------------------ overview (stats) --
  Widget _buildOverviewCard() {
    return GestureDetector(
      onTap: () => setState(() => _filter = EventStatusFilter.all),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomePalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HomePalette.purple.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: HomePalette.purpleDeep.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HomePalette.purple.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grid_view_rounded,
                      color: HomePalette.purpleLight, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes Ã©vÃ©nements',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: HomePalette.text,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'AperÃ§u rapide de votre activitÃ©',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: HomePalette.text3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: HomePalette.text2, size: 26),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _OverviewTile(
                  icon: Icons.grid_view_rounded,
                  color: HomePalette.purple,
                  value: '$_totalCount',
                  label: 'Total',
                ),
                const SizedBox(width: 8),
                _OverviewTile(
                  icon: Icons.check_circle_outline_rounded,
                  color: HomePalette.green,
                  value: '$_activeCount',
                  label: 'En cours',
                ),
                const SizedBox(width: 8),
                _OverviewTile(
                  icon: Icons.schedule_rounded,
                  color: HomePalette.amber,
                  value: '$_upcomingCount',
                  label: 'Ã€ venir',
                ),
                const SizedBox(width: 8),
                _OverviewTile(
                  icon: Icons.inventory_2_outlined,
                  color: HomePalette.blue,
                  value: '$_pastCount',
                  label: 'PassÃ©s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ---------------------------------------------------------- list header --
  Widget _buildListHeader() {
    final events = _filteredEvents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Liste des Ã©vÃ©nements',
            style: GoogleFonts.poppins(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: HomePalette.text,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: HomePalette.purple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${events.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HomePalette.purpleLight,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Trier par',
            onSelected: (v) =>
                setState(() => _sortDateDesc = v == 'date_desc'),
            color: HomePalette.tile,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort_rounded,
                    size: 16, color: HomePalette.text2),
                const SizedBox(width: 4),
                Text(
                  'Trier par',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomePalette.text2,
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: HomePalette.text2),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'date_desc',
                child: Text('Date (rÃ©cent â†’ ancien)',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: HomePalette.text)),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Text('Date (ancien â†’ rÃ©cent)',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: HomePalette.text)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _filteredEvents;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _EventDarkCard(
        wedding: events[index],
        coverBytes: _coverImages[events[index].id],
        statusInfo: _statusInfo(events[index]),
        typeLabel: _typeLabel(events[index].type),
        typeIcon: _typeIcon(events[index].type),
        typeColor: _typeColor(events[index].type),
        onTap: () => _openDetail(events[index]),
      ),
    );
  }

  (String, Color) _statusInfo(Wedding e) {
    final s = e.status.toUpperCase();
    if (s == 'ACTIVE') return ('En cours', HomePalette.purple);
    if (s == 'DRAFT') return ('Brouillon', HomePalette.text2);
    if (_isPast(e)) return ('PassÃ©', HomePalette.blue);
    return ('Ã€ venir', HomePalette.amber);
  }

  String _typeLabel(String type) => switch (type.toUpperCase()) {
    'WEDDING' => 'Mariage',
    'COLLATION' => 'Collation',
    'ANNIVERSARY' => 'Anniversaire',
    'BAPTISM' => 'BaptÃªme',
    'GRADUATION' => 'Graduation',
    _ => 'Autre',
  };

  IconData _typeIcon(String type) => switch (type.toUpperCase()) {
    'WEDDING' => Icons.favorite_outline_rounded,
    'COLLATION' => Icons.restaurant_outlined,
    'ANNIVERSARY' => Icons.cake_outlined,
    'BAPTISM' => Icons.water_drop_outlined,
    'GRADUATION' => Icons.school_outlined,
    _ => Icons.star_outline_rounded,
  };

  Color _typeColor(String type) => switch (type.toUpperCase()) {
    'WEDDING' => HomePalette.purpleLight,
    'ANNIVERSARY' => HomePalette.amber,
    'BAPTISM' => HomePalette.blue,
    'GRADUATION' => HomePalette.green,
    _ => HomePalette.text2,
  };

  // ---------------------------------------------------------------- states --
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            key: ValueKey('skeleton-$i'),
            height: 150,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: HomePalette.card,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      iconColor: HomePalette.red,
      title: 'Impossible de charger vos événements',
      message: 'Vérifiez votre connexion puis réessayez.',
      actionLabel: 'Réessayer',
      onAction: _load,
    );
  }

  Widget _buildEmpty(bool canCreate) {
    return _CenteredState(
      icon: Icons.celebration_outlined,
      iconColor: HomePalette.purple,
      title: 'Créez votre premier événement',
      message:
          'Invitez vos proches, suivez les RSVP et gérez le jour J en quelques étapes.',
      actionLabel: canCreate ? 'Créer un événement' : null,
      onAction: canCreate ? _openCreate : null,
    );
  }

  Widget _buildNoResults() {
    return _CenteredState(
      icon: Icons.search_off_rounded,
      iconColor: HomePalette.amber,
      title: 'Aucun événement trouvé',
      message: 'Essayez un autre filtre ou une autre recherche.',
    );
  }

  // ------------------------------------------------------ helpers de carte --
}

/// Carte d'événement de la maquette : badge de statut sur la photo, méta,
/// puces type/invités, chevron + menu, pied « confirmés » pour l'actif.
class _EventDarkCard extends ConsumerWidget {
  const _EventDarkCard({
    required this.wedding,
    required this.coverBytes,
    required this.statusInfo,
    required this.typeLabel,
    required this.typeIcon,
    required this.typeColor,
    required this.onTap,
  });

  final Wedding wedding;
  final Uint8List? coverBytes;
  final (String, Color) statusInfo;
  final String typeLabel;
  final IconData typeIcon;
  final Color typeColor;
  final VoidCallback onTap;

  String _dateLabel() {
    final raw = wedding.eventDate;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    String dateTxt = 'Date à confirmer';
    if (parsed != null) {
      const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      const months = [
        'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
      ];
      dateTxt =
          '${weekdays[parsed.weekday - 1]}. ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    }
    final t = wedding.startTime;
    if (t != null && t.isNotEmpty) {
      return '$dateTxt • ${t.length >= 5 ? t.substring(0, 5) : t}';
    }
    return dateTxt;
  }

  String _venueLabel() {
    final parts = [
      if ((wedding.venueName ?? '').isNotEmpty) wedding.venueName!,
      if ((wedding.city ?? '').isNotEmpty) wedding.city!,
    ];
    return parts.isEmpty ? 'Lieu à préciser' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusLabel, statusColor) = statusInfo;
    final isActive = statusLabel == 'En cours';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HomePalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.5),
                              HomePalette.purpleDeep.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          image: (coverBytes != null && coverBytes!.isNotEmpty)
                              ? DecorationImage(
                                  image: MemoryImage(coverBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (coverBytes != null && coverBytes!.isNotEmpty)
                            ? null
                            : Icon(typeIcon, size: 34, color: Colors.white70),
                      ),
                      Positioned(
                        top: 8,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                wedding.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: HomePalette.text,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              color: HomePalette.tile,
                              icon: const Icon(Icons.more_vert_rounded,
                                  size: 20, color: HomePalette.text3),
                              onSelected: (_) => onTap(),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Détails',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          color: HomePalette.text)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _MetaLine(icon: Icons.event_rounded, text: _dateLabel()),
                        const SizedBox(height: 3),
                        _MetaLine(
                            icon: Icons.location_on_outlined,
                            text: _venueLabel()),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _TypePill(
                              icon: typeIcon,
                              label: typeLabel,
                              color: typeColor,
                            ),
                            const SizedBox(width: 8),
                            _GuestCountPill(eventId: wedding.id),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 24, color: HomePalette.text3),
                ],
              ),
            ),
            if (isActive)
              _ConfirmFooter(eventId: wedding.id)
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Ligne méta (icône grise + texte).
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(

      children: [
        Icon(icon, size: 13, color: HomePalette.text3),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: HomePalette.text2,
            ),
          ),
        ),
      ],
    );
  }
}
/// Puce Â« Mariage Â» (fond teintÃ© + icÃ´ne + libellÃ© colorÃ©).
class _TypePill extends StatelessWidget {
  const _TypePill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce Â« 120 invitÃ©s Â» (fond neutre + icÃ´ne groupe).
class _GuestCountPill extends ConsumerWidget {
  const _GuestCountPill({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(eventDashboardProvider(eventId));
    final total = stats.valueOrNull?.invitations.total ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: HomePalette.tile,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined, size: 13, color: HomePalette.text2),
          const SizedBox(width: 5),
          Text(
            '$total invitÃ©${total > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: HomePalette.text2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pied de carte Â« 4 / 10 confirmÃ©s Â» + barre de progression + Â« 40 % Â».
class _ConfirmFooter extends ConsumerWidget {
  const _ConfirmFooter({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(eventDashboardProvider(eventId));
    final data = stats.valueOrNull;
    final confirmed = data?.invitations.accepted ?? 0;
    final total = data?.invitations.total ?? 0;
    final ratio = total <= 0 ? 0.0 : (confirmed / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: HomePalette.tile,
              valueColor: const AlwaysStoppedAnimation(HomePalette.purple),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$confirmed / $total confirmÃ©s',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: HomePalette.text2,
                ),
              ),
              const Spacer(),
              Text(
                '$percent %',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HomePalette.purpleLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
/// Tuile de la carte Â« Mes Ã©vÃ©nements Â» (icÃ´ne ronde + valeur + libellÃ©).
class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: HomePalette.text,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: HomePalette.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ã‰tat centrÃ© (erreur / vide / aucun rÃ©sultat).
class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: HomePalette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: HomePalette.text3,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (r) => HomePalette.purpleGradient.createShader(r),
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HomePalette.purpleDeep,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: Text(
                    actionLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
}

/// Trait manuscrit (Â« swoosh Â») sous la phrase cursive de la maquette.
class _SwooshPainter extends CustomPainter {
  _SwooshPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.6,
        size.width * 0.97,
        size.height * 0.15,
      );
    canvas.drawPath(path, paint);

    // Petite pointe de flÃ¨che Ã  droite.
    final tip = Path()
      ..moveTo(size.width * 0.82, size.height * 0.45)
      ..lineTo(size.width * 0.97, size.height * 0.15)
      ..lineTo(size.width * 0.86, size.height * 0.12);
    canvas.drawPath(tip, paint);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter oldDelegate) =>
      oldDelegate.color != color;
}












