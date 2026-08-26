import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_create_page.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/invitation/invitation_api.dart';
import '../../../../src/invitation/invitation_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_providers.dart';

enum GuestRsvpFilter { all, confirmed, pending, declined }

extension GuestRsvpFilterLabel on GuestRsvpFilter {
  String get label => switch (this) {
        GuestRsvpFilter.all => 'Tous',
        GuestRsvpFilter.confirmed => 'Confirmés',
        GuestRsvpFilter.pending => 'En attente',
        GuestRsvpFilter.declined => 'Refusés',
      };
}

class OrganisateurGuestsScreen extends ConsumerStatefulWidget {
  const OrganisateurGuestsScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<OrganisateurGuestsScreen> createState() =>
      _OrganisateurGuestsScreenState();
}

class _OrganisateurGuestsScreenState extends ConsumerState<OrganisateurGuestsScreen> {
  bool _loading = true;
  String? _error;
  List<Guest> _guests = const [];
  List<Invitation> _invitations = const [];
  Dashboard? _dashboard;
  GuestRsvpFilter _filter = GuestRsvpFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _eventName = 'Événement';

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
      _guests = const [];
      _invitations = const [];
    });
    await _loadEventName();
    await _loadGuests();
    await _loadDashboard();
  }

  Future<void> _loadEventName() async {
    try {
      final api = ref.read(weddingApiProvider);
      final events = await api.list(size: 1);
      if (!mounted) return;
      if (events.isNotEmpty) {
        setState(() => _eventName = events.first.displayName);
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _loadGuests() async {
    try {
      final guestApi = ref.read(guestApiProvider);
      final invitationApi = ref.read(invitationApiProvider);
      final results = await Future.wait([
        guestApi.listGuests(widget.weddingId),
        invitationApi.list(widget.weddingId),
      ]);
      if (!mounted) return;
      setState(() {
        _guests = results[0] as List<Guest>;
        _invitations = results[1] as List<Invitation>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les invités';
      });
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final dashApi = ref.read(dashboardApiProvider);
      final dash = await dashApi.getForWedding(widget.weddingId);
      if (!mounted) return;
      setState(() {
        _dashboard = dash;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _refresh() async {
    await _loadGuests();
    await _loadDashboard();
  }

  Map<int, Invitation> get _invitationByGuestId {
    final map = <int, Invitation>{};
    for (final inv in _invitations) {
      map[inv.guestId] = inv;
    }
    return map;
  }

  GuestRsvpStatus? _rsvpForGuest(Guest guest) {
    final inv = _invitationByGuestId[guest.id];
    if (inv == null) return null;
    return _mapRsvp(inv.status);
  }

  GuestRsvpStatus? _mapRsvp(String status) {
    final upper = status.toUpperCase();
    if (upper == 'ACCEPTED') return GuestRsvpStatus.confirmed;
    if (upper == 'DECLINED') return GuestRsvpStatus.declined;
    if (upper == 'PENDING') return GuestRsvpStatus.pending;
    return null;
  }

  List<Guest> get _filteredGuests {
    var list = _guests;
    if (_filter != GuestRsvpFilter.all) {
      list = list.where((g) {
        final rsvp = _rsvpForGuest(g);
        switch (_filter) {
          case GuestRsvpFilter.confirmed:
            return rsvp == GuestRsvpStatus.confirmed;
          case GuestRsvpFilter.pending:
            return rsvp == GuestRsvpStatus.pending;
          case GuestRsvpFilter.declined:
            return rsvp == GuestRsvpStatus.declined;
          case GuestRsvpFilter.all:
            return true;
        }
      }).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((g) {
      final name = '${g.firstName} ${g.lastName}'.toLowerCase();
      final email = (g.email ?? '').toLowerCase();
      final phone = (g.phone ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canCreate = auth.hasPermission(PermissionCodes.guestCreate);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scheme, _eventName, canCreate),
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
                      _buildListHeader(scheme, canCreate),
                      const SizedBox(height: AppSpacing.lg),
                      if (_loading)
                        _buildSkeleton()
                      else if (_error != null)
                        _buildError()
                      else if (_filteredGuests.isEmpty)
                        _buildEmptySearch()
                      else
                        _buildGuestList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, String eventName, bool canCreate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invités',
                  style: AppTypography.cardTitle(color: scheme.onSurface)
                      .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(
                  eventName,
                  style: AppTypography.small(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCreate)
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                textStyle: AppTypography.small().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
                border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                },
                style: AppTypography.body(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Rechercher un invité (nom, email, téléphone...)',
                  hintStyle: AppTypography.body(color: scheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, size: 22, color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              onPressed: _showFilterOptions,
              icon: Icon(Icons.tune_rounded, size: 22, color: scheme.onSurface),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: GuestRsvpFilter.values.map((f) {
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
                  color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme scheme) {
    final dash = _dashboard;
    final totalGuests = dash?.guests.total ?? 0;
    final totalInvitations = dash?.invitations.total ?? 0;
    final confirmed = dash?.invitations.accepted ?? 0;
    final checkedIn = dash?.attendance.checkedIn ?? 0;

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
              icon: Icons.group_outlined,
              iconBg: scheme.primaryContainer,
              iconColor: scheme.primary,
              value: '$totalGuests',
              label: 'Invités',
            ),
          ),
          Container(width: 1, height: 40, color: scheme.outline.withValues(alpha: 0.3)),
          Expanded(
            child: _StatItem(
              icon: Icons.verified_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF22C55E),
              value: '$confirmed',
              label: 'Confirmés',
            ),
          ),
          Container(width: 1, height: 40, color: scheme.outline.withValues(alpha: 0.3)),
          Expanded(
            child: _StatItem(
              icon: Icons.schedule_outlined,
              iconBg: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFF59E0B),
              value: '$totalInvitations',
              label: 'Invités',
            ),
          ),
          Container(width: 1, height: 40, color: scheme.outline.withValues(alpha: 0.3)),
          Expanded(
            child: _StatItem(
              icon: Icons.cancel_outlined,
              iconBg: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              value: '$checkedIn',
              label: 'Présents',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(ColorScheme scheme, bool canCreate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Liste des invités',
            style: AppTypography.sectionTitle(color: scheme.onSurface),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.sort_rounded, size: 18, color: scheme.primary),
            label: Text('Trier', style: AppTypography.small(color: scheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Shimmer(
              width: double.infinity,
              height: 80,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error.withValues(alpha: 0.6)),
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

  Widget _buildEmptySearch() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Aucun invité ne correspond à votre recherche',
              style: AppTypography.body(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestList() {
    final filtered = _filteredGuests;
    if (filtered.isEmpty && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Aucun invité pour le moment',
                style: AppTypography.body(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: filtered.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final guest = filtered[index];
        return _OrganizerGuestTile(
          guest: guest,
          rsvp: _rsvpForGuest(guest),
          onTap: () => _openGuestDetail(guest),
        );
      },
    );
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestCreatePage(weddingId: widget.weddingId),
      ),
    );
  }

  void _openGuestDetail(Guest guest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détail de ${guest.displayName} (à venir)')),
    );
  }

  void _showFilterOptions() {
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
              leading: Icon(Icons.sort_by_alpha_rounded),
              title: Text('Trier par nom'),
            ),
            const ListTile(
              leading: Icon(Icons.calendar_today_outlined),
              title: Text('Trier par date d\'ajout'),
            ),
          ],
        ),
      ),
    );
  }
}

enum GuestRsvpStatus { confirmed, pending, declined }

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
        Text(value, style: AppTypography.stat(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.small(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _OrganizerGuestTile extends StatelessWidget {
  const _OrganizerGuestTile({
    required this.guest,
    required this.rsvp,
    required this.onTap,
  });

  final Guest guest;
  final GuestRsvpStatus? rsvp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = guest.displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    Color badgeColor;
    Color badgeBg;
    String badgeLabel;
    IconData? badgeIcon;
    switch (rsvp) {
      case GuestRsvpStatus.confirmed:
        badgeColor = const Color(0xFF22C55E);
        badgeBg = const Color(0xFFE8F5E9);
        badgeLabel = 'Confirmé';
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
      case GuestRsvpStatus.pending:
        badgeColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFFFFBEB);
        badgeLabel = 'En attente';
        badgeIcon = Icons.schedule_outlined;
        break;
      case GuestRsvpStatus.declined:
        badgeColor = const Color(0xFFEF4444);
        badgeBg = const Color(0xFFFEF2F2);
        badgeLabel = 'Refusé';
        badgeIcon = Icons.cancel_outlined;
        break;
      case null:
        badgeColor = scheme.onSurfaceVariant;
        badgeBg = scheme.surfaceContainerHighest;
        badgeLabel = 'Non invité';
        badgeIcon = null;
    }

    final contact = guest.phone ?? guest.email ?? '';
    final companions = guest.allowedCompanions;
    final persons = companions != null && companions > 0 ? '+$companions pers.' : null;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: AppTypography.subtitle(color: scheme.primary)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            guest.displayName,
                            style: AppTypography.cardTitle(color: scheme.onSurface)
                                .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeIcon != null) ...[
                                Icon(badgeIcon, size: 14, color: badgeColor),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                badgeLabel,
                                style: AppTypography.small(color: badgeColor)
                                    .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (contact.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact,
                              style: AppTypography.small(color: scheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (persons != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            persons,
                            style: AppTypography.small(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: scheme.onSurfaceVariant),
            ],
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
