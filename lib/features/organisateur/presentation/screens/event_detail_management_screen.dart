import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/auth/auth_controller.dart';
import '../../../../src/auth/auth_models.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/guest/guest_create_page.dart';
import '../../../../src/guest/guest_list_page.dart';
import '../../../../src/invitation/invitation_create_page.dart';
import '../../../../src/invitation/invitation_list_page.dart';
import '../../../../src/table/table_list_page.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../../../src/weddingevent/wedding_event_list_page.dart';
import '../../shared/widgets/app_states.dart';

class EventDetailManagementScreen extends ConsumerStatefulWidget {
  const EventDetailManagementScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<EventDetailManagementScreen> createState() =>
      _EventDetailManagementScreenState();
}

class _EventDetailManagementScreenState extends ConsumerState<EventDetailManagementScreen> {
  bool _loading = true;
  String? _error;
  Wedding? _wedding;
  Dashboard? _dashboard;

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
      final w = await ref.read(weddingApiProvider).getById(widget.weddingId);
      Dashboard? d;
      try {
        d = await ref.read(dashboardApiProvider).getForWedding(widget.weddingId);
      } catch (_) {
        d = null;
      }
      if (!mounted) return;
      setState(() {
        _wedding = w;
        _dashboard = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger l\'événement';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _loading
          ? const AppLoadingState()
          : _error != null
              ? AppErrorState(onRetry: _load)
              : _wedding == null
                  ? const AppEmptyState(icon: Icons.error, title: 'Élément introuvable')
                  : _buildContent(scheme, auth),
    );
  }

  Widget _buildContent(ColorScheme scheme, AuthState auth) {
    final w = _wedding!;
    final d = _dashboard;
    final status = w.status.toUpperCase();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: scheme.surface,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: scheme.onSurface),
          ),
          title: Text(
            'Détails de l\'événement',
            style: AppTypography.cardTitle(color: scheme.onSurface),
          ),
          actions: [
            if (auth.hasPermission(PermissionCodes.weddingUpdate))
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit_outlined, size: 22, color: scheme.onSurface),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 22, color: scheme.onSurface),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                if (auth.hasPermission(PermissionCodes.weddingPublish)) {
                  items.add(const PopupMenuItem(value: 'publish', child: Text('Publier')));
                }
                if (auth.hasPermission(PermissionCodes.weddingArchive)) {
                  items.add(const PopupMenuItem(value: 'archive', child: Text('Archiver')));
                }
                if (auth.hasPermission(PermissionCodes.weddingDelete)) {
                  items.add(const PopupMenuItem(value: 'delete', child: Text('Supprimer')));
                }
                if (items.isEmpty) {
                  items.add(const PopupMenuItem(value: 'none', child: Text('Aucune action disponible')));
                }
                return items;
              },
              onSelected: _onMenuAction,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildCoverCard(scheme, w, status),
              const SizedBox(height: AppSpacing.lg),
              _buildInfoCard(scheme, w),
              const SizedBox(height: AppSpacing.xxl),
              _buildStatisticsCard(scheme, d),
              const SizedBox(height: AppSpacing.xxl),
              _buildManagementSection(scheme, auth, w.id),
              const SizedBox(height: AppSpacing.xxl),
              _buildQuickActions(scheme, auth, w.id),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverCard(ColorScheme scheme, Wedding w, String status) {
    final statusLabel = _statusLabel(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 15,
              bottom: 5,
              child: Opacity(
                opacity: 0.25,
                child: Text('✨', style: const TextStyle(fontSize: 90)),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTypography.small(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w.displayName,
                    style: AppTypography.display(color: Colors.white).copyWith(fontSize: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme scheme, Wedding w) {
    final names = '${w.groomFirstName} ${w.brideFirstName}'.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              w.displayName,
              style: AppTypography.cardTitle(color: scheme.onSurface)
                  .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      names,
                      style: AppTypography.body(color: scheme.onSurfaceVariant)
                          .copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Organisation #${w.organizationId}',
                    style: AppTypography.body(color: scheme.onSurfaceVariant)
                        .copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(ColorScheme scheme, Dashboard? d) {
    final guests = d?.guests.total ?? 0;
    final confirmed = d?.invitations.accepted ?? 0;
    final checkedIn = d?.attendance.checkedIn ?? 0;
    final pending = d?.invitations.pending ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(child: _DetailStatItem(icon: Icons.group_outlined, iconBg: scheme.primaryContainer, iconColor: scheme.primary, value: '$guests', label: 'Invités')),
            Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.3)),
            Expanded(child: _DetailStatItem(icon: Icons.verified_outlined, iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF22C55E), value: '$confirmed', label: 'Confirmés')),
            Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.3)),
            Expanded(child: _DetailStatItem(icon: Icons.qr_code_scanner_outlined, iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B), value: '$checkedIn', label: 'Présents')),
            Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.3)),
            Expanded(child: _DetailStatItem(icon: Icons.schedule_outlined, iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B), value: '$pending', label: 'En attente')),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(ColorScheme scheme, AuthState auth, int weddingId) {
    final modules = <_ModuleCardData>[
      _ModuleCardData(
        icon: Icons.group_outlined,
        title: 'Invités',
        description: 'Gérer votre liste d\'invités',
        color: scheme.primary,
        background: scheme.primaryContainer,
        onTap: auth.hasPermission(PermissionCodes.guestView)
            ? () => _openGuestList(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.mail_outline,
        title: 'Invitations',
        description: 'Créer et suivre les invitations',
        color: scheme.primary,
        background: scheme.primaryContainer,
        onTap: auth.hasPermission(PermissionCodes.invitationView)
            ? () => _openInvitations(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.fact_check_outlined,
        title: 'RSVP',
        description: 'Voir les réponses des invités',
        color: const Color(0xFF22C55E),
        background: const Color(0xFFE8F5E9),
        onTap: auth.hasPermission(PermissionCodes.invitationView)
            ? () => _openInvitations(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.qr_code_scanner_outlined,
        title: 'Check-in',
        description: 'Enregistrer les arrivées',
        color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFFBEB),
        onTap: auth.hasPermission(PermissionCodes.checkinCreate)
            ? () => _openCheckin(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.table_restaurant_outlined,
        title: 'Tables',
        description: 'Organiser le placement',
        color: scheme.primary,
        background: scheme.primaryContainer,
        onTap: auth.hasPermission(PermissionCodes.tableCreate)
            ? () => _openTables(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.calendar_month_outlined,
        title: 'Activités',
        description: 'Gérer le programme',
        color: scheme.primary,
        background: scheme.primaryContainer,
        onTap: auth.hasPermission(PermissionCodes.eventView)
            ? () => _openActivities(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.bar_chart_outlined,
        title: 'Statistiques',
        description: 'Consulter les performances',
        color: const Color(0xFF22C55E),
        background: const Color(0xFFE8F5E9),
        onTap: auth.hasPermission(PermissionCodes.dashboardView)
            ? () {}
            : null,
      ),
      _ModuleCardData(
        icon: Icons.settings_outlined,
        title: 'Paramètres',
        description: 'Configurer l\'événement',
        color: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
        onTap: auth.hasPermission(PermissionCodes.weddingUpdate)
            ? () {}
            : null,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gérer cet événement',
            style: AppTypography.sectionTitle(color: scheme.onSurface),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 130,
            ),
            itemBuilder: (context, index) => _ModuleCard(module: modules[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme scheme, AuthState auth, int weddingId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: AppTypography.sectionTitle(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'Ajouter un invité',
                  primary: true,
                  onTap: auth.hasPermission(PermissionCodes.guestCreate)
                      ? () => _openAddGuest(weddingId)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.send_outlined,
                  label: 'Créer invitation',
                  primary: false,
                  onTap: auth.hasPermission(PermissionCodes.invitationCreate)
                      ? () => _openCreateInvitation(weddingId)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGuestList(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GuestListPage(weddingId: weddingId)),
    );
  }

  void _openInvitations(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InvitationListPage(weddingId: weddingId)),
    );
  }

  void _openCheckin(int weddingId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in : module à venir')),
    );
  }

  void _openTables(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TableListPage(weddingId: weddingId)),
    );
  }

  void _openActivities(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeddingEventListPage(weddingId: weddingId)),
    );
  }

  void _openAddGuest(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GuestCreatePage(weddingId: weddingId)),
    );
  }

  void _openCreateInvitation(int weddingId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InvitationCreatePage(weddingId: weddingId)),
    );
  }

  /// Exécute une action du menu ⋮ (Publier / Archiver / Supprimer).
  /// Chaque action n'apparaît que si la permission UI est présente (le backend
  /// reste l'autorité). La suppression demande une confirmation.
  Future<void> _onMenuAction(String? value) async {
    final w = _wedding;
    if (w == null || value == null || value == 'none') return;
    final api = ref.read(weddingApiProvider);
    switch (value) {
      case 'publish':
        try {
          await api.updateStatus(w.id, 'PUBLISHED');
          await _load();
        } catch (_) {
          _toast('Publication impossible');
        }
        break;
      case 'archive':
        try {
          await api.updateStatus(w.id, 'ARCHIVED');
          await _load();
        } catch (_) {
          _toast('Archivage impossible');
        }
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer cet événement ?'),
            content: const Text(
                'Cette action supprimera l\u2019événement et ses données.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Retour')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626)),
                  child: const Text('Supprimer')),
            ],
          ),
        );
        if (ok != true) return;
        try {
          await api.delete(w.id);
          if (mounted) Navigator.of(context).pop(true);
        } catch (_) {
          _toast('Suppression impossible');
        }
        break;
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _statusLabel(String status) => switch (status) {
        'ACTIVE' || 'PUBLISHED' => 'En cours',
        'DRAFT' => 'Brouillon',
        _ => 'À venir',
      };
}

class _ModuleCardData {
  const _ModuleCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _ModuleCardData module;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: module.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.icon, size: 20, color: module.color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  module.title,
                  style: AppTypography.cardTitle(color: scheme.onSurface)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  module.description,
                  style: AppTypography.small(color: scheme.onSurfaceVariant)
                      .copyWith(fontSize: 11, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: primary ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: primary ? null : Border.all(color: scheme.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: primary ? Colors.white : scheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.button(
                  color: primary ? Colors.white : scheme.primary,
                ).copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatItem extends StatelessWidget {
  const _DetailStatItem({
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.stat(color: Theme.of(context).colorScheme.onSurface)
              .copyWith(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.small(color: Theme.of(context).colorScheme.onSurfaceVariant)
              .copyWith(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
