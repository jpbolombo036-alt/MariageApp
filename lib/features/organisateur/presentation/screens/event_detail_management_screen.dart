import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
import '../../../../src/checkin/checkin_scan_page.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../../../src/weddingevent/wedding_event_list_page.dart';
import '../../shared/widgets/app_states.dart';
import 'event_tools_screen.dart';

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
  Uint8List? _coverBytes;
  Uint8List? _groomBytes;
  Uint8List? _brideBytes;
  Uint8List? _coupleBytes;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCover();
    _loadDetailPhotos();
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

  Future<void> _loadCover() async {
    try {
      final bytes = await ref.read(weddingApiProvider).loadImage(widget.weddingId);
      if (!mounted) return;
      setState(() => _coverBytes = bytes);
    } catch (_) {}
  }

  Future<void> _loadDetailPhotos() async {
    try {
      final api = ref.read(weddingApiProvider);
      final groom = await api.loadDetailPhoto(widget.weddingId, 'groom');
      final bride = await api.loadDetailPhoto(widget.weddingId, 'bride');
      final couple = await api.loadDetailPhoto(widget.weddingId, 'couple');
      if (!mounted) return;
      setState(() {
        _groomBytes = groom;
        _brideBytes = bride;
        _coupleBytes = couple;
      });
    } catch (_) {}
  }

  Future<void> _pickAndUploadCoverImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      await ref.read(weddingApiProvider).uploadImage(widget.weddingId, bytes, mime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de couverture mise à jour')),
      );
      await _loadCover();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload impossible')),
      );
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
                final items = <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'tools', child: Text('Outils')),
                ];
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
              const SizedBox(height: AppSpacing.xl),
              _buildCouplePhotosCard(scheme),
              const SizedBox(height: AppSpacing.xl),
              _buildStatisticsCard(scheme, d),
              const SizedBox(height: AppSpacing.xxl),
              _buildManagementSection(scheme, auth, w.id, d),
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
    final city = (w.city ?? '').trim();
    final typeLabel = _eventTypeLabelOf(w.type);
    final subtitle = [
      'Célébration de $typeLabel',
      if (city.isNotEmpty) city,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (_coverBytes != null)
              Positioned.fill(
                child: Image.memory(
                  _coverBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [OrganizerColors.primaryDark, OrganizerColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -6,
              top: 24,
              child: Icon(
                Icons.star_rounded,
                size: 92,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: OrganizerColors.successOnDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'CÉLÉBRATION',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    w.displayName,
                    style: AppTypography.display(color: Colors.white).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _heroMetaRow(Icons.event_rounded, _heroDateLine(w)),
                  const SizedBox(height: 6),
                  _heroMetaRow(Icons.place_rounded, _heroVenueLine(w)),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                onPressed: _pickAndUploadCoverImage,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                tooltip: 'Changer la photo de couverture',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouplePhotosCard(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos du couple',
            style: AppTypography.sectionTitle(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _PhotoThumbnail(label: 'Marié', bytes: _groomBytes, scheme: scheme)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _PhotoThumbnail(label: 'Mariée', bytes: _brideBytes, scheme: scheme)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _PhotoThumbnail(label: 'Couple', bytes: _coupleBytes, scheme: scheme)),
            ],
          ),
        ],
      ),
    );
  }

  /// Ligne d'information blanche du hero (icône + texte).
  Widget _heroMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  /// Bas de la carte statistiques : « Taux de pointage actuel » + barre.
  Widget _buildAttendanceProgress(ColorScheme scheme, Dashboard? d) {
    final rate = _normalizedRate(d?.attendance.checkInRate ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Taux de pointage actuel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small(
                  color: scheme.onSurfaceVariant,
                ).copyWith(fontSize: 12),
              ),
            ),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: AppTypography.small(color: scheme.onSurface).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            color: scheme.outline.withValues(alpha: 0.35),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (rate / 100).clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OrganizerColors.primary, OrganizerColors.accent],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
                Expanded(
                  child: _DetailStatItem(
                    icon: Icons.group_outlined,
                    iconBg: scheme.primary.withValues(alpha: 0.12),
                    iconColor: scheme.primary,
                    value: '$guests',
                    label: 'Invités',
                  ),
                ),
                Expanded(
                  child: _DetailStatItem(
                    icon: Icons.verified_outlined,
                    iconBg: OrganizerColors.successBg,
                    iconColor: OrganizerColors.success,
                    value: '$confirmed',
                    label: 'Confirmés',
                  ),
                ),
                Expanded(
                  child: _DetailStatItem(
                    icon: Icons.groups_2_outlined,
                    iconBg: OrganizerColors.warningBg,
                    iconColor: OrganizerColors.warning,
                    value: '$checkedIn',
                    label: 'Présents',
                  ),
                ),
                Expanded(
                  child: _DetailStatItem(
                    icon: Icons.schedule_rounded,
                    iconBg: OrganizerColors.warningBg,
                    iconColor: OrganizerColors.warning,
                    value: '$pending',
                    label: 'En attente',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.lg),
            _buildAttendanceProgress(scheme, d),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(
    ColorScheme scheme,
    AuthState auth,
    int weddingId,
    Dashboard? d,
  ) {
    final modules = <_ModuleCardData>[
      _ModuleCardData(
        icon: Icons.group_outlined,
        title: 'Invités',
        description: 'Gérer votre liste d\'invités',
        color: scheme.primary,
        background: scheme.primary.withValues(alpha: 0.12),
        trailing: _ModuleTrailing.count('${d?.guests.total ?? 0}'),
        onTap: auth.hasPermission(PermissionCodes.guestView)
            ? () => _openGuestList(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.mail_outline,
        title: 'Invitations',
        description: 'Créer et suivre les invitations',
        color: scheme.primary,
        background: scheme.primary.withValues(alpha: 0.12),
        trailing: const _ModuleTrailing.dot(),
        onTap: auth.hasPermission(PermissionCodes.invitationView)
            ? () => _openInvitations(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.fact_check_outlined,
        title: 'RSVP',
        description: 'Voir les réponses des invités',
        color: OrganizerColors.success,
        background: OrganizerColors.successBg,
        trailing: const _ModuleTrailing.badge(
          'Actif',
          color: OrganizerColors.success,
          background: OrganizerColors.successBg,
        ),
        onTap: auth.hasPermission(PermissionCodes.invitationView)
            ? () => _openInvitations(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.qr_code_scanner_outlined,
        title: 'Check-in',
        description: 'Enregistrer les arrivées',
        color: OrganizerColors.warning,
        background: OrganizerColors.warningBg,
        trailing: const _ModuleTrailing.badge(
          'Scan direct',
          color: OrganizerColors.warning,
          background: OrganizerColors.warningBg,
        ),
        onTap: auth.hasPermission(PermissionCodes.checkinCreate)
            ? () => _openCheckin(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.table_restaurant_outlined,
        title: 'Tables',
        description: 'Organiser le placement',
        color: OrganizerColors.info,
        background: OrganizerColors.infoBg,
        onTap: auth.hasPermission(PermissionCodes.tableCreate)
            ? () => _openTables(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.calendar_month_outlined,
        title: 'Activités',
        description: 'Gérer le programme',
        color: scheme.primary,
        background: scheme.primary.withValues(alpha: 0.12),
        onTap: auth.hasPermission(PermissionCodes.eventView)
            ? () => _openActivities(weddingId)
            : null,
      ),
      _ModuleCardData(
        icon: Icons.bar_chart_outlined,
        title: 'Statistiques',
        description: 'Consulter les performances',
        color: OrganizerColors.success,
        background: OrganizerColors.successBg,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gérer cet événement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(color: scheme.onSurface)
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${modules.length} modules',
                style: AppTypography.small(color: scheme.primary)
                    .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 150,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckInScanPage(weddingId: weddingId),
      ),
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

  Future<void> _openAddGuest(int weddingId) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GuestCreatePage(weddingId: weddingId)),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openCreateInvitation(int weddingId) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvitationCreatePage(weddingId: weddingId),
      ),
    );
    if (created == true && mounted) await _load();
  }

  /// Exécute une action du menu ⋮ (Publier / Archiver / Supprimer).
  /// Chaque action n'apparaît que si la permission UI est présente (le backend
  /// reste l'autorité). La suppression demande une confirmation.
  Future<void> _onMenuAction(String? value) async {
    final w = _wedding;
    if (w == null || value == null || value == 'none') return;
    final api = ref.read(weddingApiProvider);
    switch (value) {
      case 'tools':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EventToolsScreen(weddingId: w.id),
          ),
        );
        break;
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
                      foregroundColor: OrganizerColors.danger),
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
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;

  /// Indicateur en haut à droite (compteur, pastille ou badge).
  final _ModuleTrailing? trailing;
  final VoidCallback? onTap;
}

/// Indicateur affiché en haut à droite d'une carte module.
class _ModuleTrailing {
  /// Compteur simple en violet (ex. « 54 »).
  const _ModuleTrailing.count(this.text)
      : dot = false,
        background = null,
        color = OrganizerColors.primary;

  /// Pastille verte (module actif).
  const _ModuleTrailing.dot()
      : text = '',
        dot = true,
        background = null,
        color = OrganizerColors.success;

  /// Badge coloré (« Actif », « Scan direct »).
  const _ModuleTrailing.badge(
    this.text, {
    required this.color,
    required this.background,
  }) : dot = false;

  final String text;
  final bool dot;
  final Color color;
  final Color? background;
}

/// Libellé du type d'événement (`Mariage`, `Anniversaire`, ...).
String _eventTypeLabelOf(String type) => switch (type.toUpperCase()) {
  'WEDDING' => 'Mariage',
  'COLLATION' => 'Collation',
  'ANNIVERSARY' => 'Anniversaire',
  'BAPTISM' => 'Baptême',
  'GRADUATION' => 'Remise de diplôme',
  _ => 'Événement',
};

/// « Samedi 28 Juin 2025 • 15h00 » (sans dépendance `intl`).
String _heroDateLine(Wedding w) {
  final date = _frenchDate(w.eventDate);
  final time = _frenchTime(w.startTime);
  final parts = <String>[?date, ?time];
  if (parts.isEmpty) return 'Date à définir';
  return parts.join(' • ');
}

/// « Organisation #1 • Salle Majestic Pullman ».
String _heroVenueLine(Wedding w) {
  final venue = (w.venueName ?? '').trim();
  final city = (w.city ?? '').trim();
  final buffer = StringBuffer('Organisation #${w.organizationId}');
  if (venue.isNotEmpty) {
    buffer.write(' • $venue');
  } else if (city.isNotEmpty) {
    buffer.write(' • $city');
  }
  return buffer.toString();
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

/// Ramène un taux d'API (0-1 ou 0-100) en pourcentage.
double _normalizedRate(double value) {
  if (value <= 0) return 0;
  return value <= 1 ? value * 100 : value;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _ModuleCardData module;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trailing = module.trailing;
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          boxShadow: AppShadows.subtle(scheme.shadow),
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
                    color: module.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, size: 20, color: module.color),
                ),
                const Spacer(),
                if (trailing != null) _buildTrailing(trailing),
              ],
            ),
            const Spacer(),
            Text(
              module.title,
              style: AppTypography.cardTitle(color: scheme.onSurface).copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              module.description,
              style: AppTypography.small(color: scheme.onSurfaceVariant)
                  .copyWith(fontSize: 11, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Compteur violet, pastille verte ou badge coloré.
  Widget _buildTrailing(_ModuleTrailing trailing) {
    if (trailing.dot) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: trailing.color,
          shape: BoxShape.circle,
        ),
      );
    }
    if (trailing.background == null) {
      return Text(
        trailing.text,
        style: TextStyle(
          color: trailing.color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: trailing.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        trailing.text,
        style: TextStyle(
          color: trailing.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.cardTitle(color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.small(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.label, required this.bytes, required this.scheme});

  final String label;
  final Uint8List? bytes;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 120,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.small(color: scheme.onSurfaceVariant),
        ),
      ),
    );
    if (bytes == null) return placeholder;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
