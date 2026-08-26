import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/organisateur_home_widgets.dart';
import 'evenement_create_stepper_screen.dart';
import 'evenement_detail_screen.dart';
import 'mes_evenements_screen.dart';

class OrganisateurDashboardTab extends ConsumerStatefulWidget {
  const OrganisateurDashboardTab({super.key});

  @override
  ConsumerState<OrganisateurDashboardTab> createState() =>
      _OrganisateurDashboardTabState();
}

class _OrganisateurDashboardTabState
    extends ConsumerState<OrganisateurDashboardTab> {
  bool _loading = true;
  List<Wedding> _events = const [];
  Wedding? _activeEvent;
  Dashboard? _dashboard;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _dashboard = null;
    });
    try {
      final events = await ref.read(weddingApiProvider).list(size: 25);
      if (!mounted) return;
      setState(() {
        _events = events;
        _activeEvent = events.isNotEmpty ? events.first : null;
        _loading = false;
      });
      if (_activeEvent != null) {
        await _loadDashboard(_activeEvent!.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les événements';
      });
    }
  }

  Future<void> _loadDashboard(int weddingId) async {
    try {
      final dash = await ref.read(dashboardApiProvider).getForWedding(weddingId);
      if (!mounted) return;
      setState(() => _dashboard = dash);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dashboard = null);
    }
  }

  Future<void> _refresh() async {
    await _load();
    if (_activeEvent != null) {
      await _loadDashboard(_activeEvent!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final rawFirstName = user?.firstName ?? '';
    final firstName = rawFirstName.isNotEmpty ? rawFirstName : 'Invité';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            OrganizerHomeHeader(
              userName: firstName,
              onNotificationTap: () {},
              onAvatarTap: () {},
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildWelcome(firstName),
            const SizedBox(height: AppSpacing.xxl),
            if (_loading)
              const OrganizerHomeSkeleton()
            else if (_error != null)
              OrganizerHomeErrorState(onRetry: _refresh)
            else if (_events.isEmpty)
              OrganizerHomeEmptyState(onAction: _openCreate)
            else
              _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(String firstName) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour,',
            style: AppTypography.body(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$firstName 👋',
            style: AppTypography.display(color: scheme.onSurface)
                .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez vos événements et suivez vos invités en temps réel.',
            style: AppTypography.body(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActiveEventCard(
          eventName: _activeEvent?.displayName ?? '',
          status: _activeEvent?.status ?? '',
          names: _formatNames(_activeEvent),
          onTap: _activeEvent != null
              ? () => _openDetails(_activeEvent!.id)
              : null,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildStatsSection(),
        const SizedBox(height: AppSpacing.xxl),
        _buildRecentEvents(),
      ],
    );
  }

  Widget _buildStatsSection() {
    final scheme = Theme.of(context).colorScheme;
    final dash = _dashboard;

    final guests = dash?.guests.total ?? 0;
    final invitations = dash?.invitations.total ?? 0;
    final confirmed = dash?.invitations.accepted ?? 0;
    final checkedIn = dash?.attendance.checkedIn ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vue d\'ensemble',
                style: AppTypography.sectionTitle(color: scheme.onSurface),
              ),
              TextButton(
                onPressed: _openEventsList,
                child: Text(
                  'Voir tout',
                  style: AppTypography.small(color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.group_outlined,
                  value: '$guests',
                  label: 'Invités',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.mail_outline,
                  value: '$invitations',
                  label: 'Invitations',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.task_alt_outlined,
                  value: '$confirmed',
                  label: 'Confirmés',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.qr_code_scanner_outlined,
                  value: '$checkedIn',
                  label: 'Présents',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEvents() {
    final scheme = Theme.of(context).colorScheme;
    final recent = _events.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes événements',
                style: AppTypography.sectionTitle(color: scheme.onSurface),
              ),
              TextButton(
                onPressed: _openEventsList,
                child: Text(
                  'Voir tout',
                  style: AppTypography.small(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final e = recent[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < recent.length - 1 ? AppSpacing.md : 0,
                ),
                child: EventPreviewCard(
                  name: e.displayName,
                  names: _formatNames(e),
                  guestsCount: 0,
                  onTap: () => _openDetails(e.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatNames(Wedding? e) {
    if (e == null) return '';
    final parts = <String>[
      if (e.groomFirstName.isNotEmpty) e.groomFirstName,
      if (e.brideFirstName.isNotEmpty) e.brideFirstName,
    ];
    return parts.join(' & ');
  }

  void _openDetails(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvenementDetailScreen(weddingId: id),
      ),
    );
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EvenementCreateStepperScreen()),
    );
  }

  void _openEventsList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MesEvenementsScreen()),
    );
  }
}
