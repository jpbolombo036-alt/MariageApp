import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_models.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../../../src/weddingevent/wedding_event_api.dart';
import '../../../../src/weddingevent/wedding_event_providers.dart';

/// Filtres du programme des temps forts.
enum ProgramFilter { all, ceremonies, reception }

extension ProgramFilterX on ProgramFilter {
  String get label => switch (this) {
    ProgramFilter.all => 'Tous les temps forts',
    ProgramFilter.ceremonies => 'Cérémonies',
    ProgramFilter.reception => 'Réception',
  };
}

/// Onglet « Calendrier » : programme des temps forts, groupés par jour.
class CalendrierOnglet extends ConsumerStatefulWidget {
  const CalendrierOnglet({super.key});

  @override
  ConsumerState<CalendrierOnglet> createState() => _CalendrierOngletState();
}

class _CalendrierOngletState extends ConsumerState<CalendrierOnglet> {
  static const _stripLength = 5;

  bool _loading = true;
  String? _error;
  Wedding? _wedding;
  List<WeddingEvent> _sessions = const [];

  ProgramFilter _filter = ProgramFilter.all;
  DateTime _selectedDay = _dateOnly(DateTime.now());
  late DateTime _stripBase;
  bool _anchored = false;

  @override
  void initState() {
    super.initState();
    _stripBase = _dateOnly(DateTime.now()).subtract(
      const Duration(days: _stripLength ~/ 2),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weddings = await ref.read(weddingApiProvider).list(size: 25);
      if (!mounted) return;
      if (weddings.isEmpty) {
        setState(() {
          _wedding = null;
          _sessions = const [];
          _loading = false;
        });
        return;
      }
      final wedding = weddings.first;
      final sessions = await ref
          .read(weddingEventApiProvider)
          .list(wedding.id, size: 100);
      if (!mounted) return;
      setState(() {
        _wedding = wedding;
        _sessions = sessions;
        if (!_anchored) {
          _selectedDay = _anchorDay(wedding, sessions);
          _stripBase = _selectedDay.subtract(
            const Duration(days: _stripLength ~/ 2),
          );
          _anchored = true;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le programme';
      });
    }
  }

  // --- Données dérivées ---------------------------------------------------

  bool get _isEventDay =>
      _sameDay(_parseDate(_wedding?.eventDate), _selectedDay);

  DateTime _anchorDay(Wedding wedding, List<WeddingEvent> sessions) {
    final today = _dateOnly(DateTime.now());
    if (sessions.any((e) => _sameDay(_parseDate(e.eventDate), today))) {
      return today;
    }
    final eventDay = _parseDate(wedding.eventDate);
    if (eventDay != null) return _dateOnly(eventDay);
    final dates = sessions
        .map((e) => _parseDate(e.eventDate))
        .whereType<DateTime>()
        .toList()
      ..sort();
    return dates.isEmpty ? today : _dateOnly(dates.first);
  }

  bool _matches(WeddingEvent session, ProgramFilter filter) {
    final type = session.typeEnum;
    return switch (filter) {
      ProgramFilter.all => true,
      ProgramFilter.ceremonies =>
        type == WeddingEventType.civilCeremony ||
            type == WeddingEventType.religiousCeremony,
      ProgramFilter.reception =>
        type == WeddingEventType.reception ||
            type == WeddingEventType.afterParty ||
            type == null,
    };
  }

  List<WeddingEvent> get _daySessions {
    final list = _sessions
        .where((e) => _sameDay(_parseDate(e.eventDate), _selectedDay))
        .toList();
    list.sort((a, b) => (a.startTime ?? '99').compareTo(b.startTime ?? '99'));
    return list;
  }

  List<WeddingEvent> get _visibleSessions =>
      _daySessions.where((e) => _matches(e, _filter)).toList();

  int _countOf(ProgramFilter filter) =>
      _daySessions.where((e) => _matches(e, filter)).length;

  bool _hasSessionsOn(DateTime day) =>
      _sessions.any((e) => _sameDay(_parseDate(e.eventDate), day));

  /// Statut d'une étape du programme (validé / en cours / clé / à venir).
  _SessionStatus _statusOf(WeddingEvent session, int index) {
    final day = _parseDate(session.eventDate);
    if (day == null) {
      return const _SessionStatus(
        label: 'Sans date',
        color: OrganizerColors.muted,
        background: OrganizerColors.mutedBg,
        icon: Icons.help_outline_rounded,
      );
    }
    final now = DateTime.now();
    final start = _atTime(day, session.startTime);
    final end =
        _atTime(day, session.endTime) ?? start?.add(_fallbackSessionDuration);
    if (end != null && now.isAfter(end)) {
      return _SessionStatus(
        label: _sameDay(day, _dateOnly(now)) ? 'Validé' : 'Terminé',
        color: OrganizerColors.success,
        background: OrganizerColors.successBg,
        icon: Icons.check_circle_outline_rounded,
      );
    }
    if (start != null && now.isAfter(start)) {
      return const _SessionStatus(
        label: 'En cours',
        color: OrganizerColors.success,
        background: OrganizerColors.successBg,
        icon: Icons.play_circle_outline_rounded,
      );
    }
    if (index == 0) {
      return const _SessionStatus(
        label: 'Moment clé',
        color: OrganizerColors.primary,
        background: OrganizerColors.lightSurfaceViolet,
        icon: Icons.auto_awesome_rounded,
      );
    }
    return const _SessionStatus(
      label: 'À venir',
      color: OrganizerColors.muted,
      background: OrganizerColors.mutedBg,
      icon: Icons.schedule_rounded,
    );
  }
  /// Formulaire « + Étape » (création) ou modification d'une étape.
  Future<void> _openSessionForm({WeddingEvent? session}) async {
    final wedding = _wedding;
    if (wedding == null) return;
    final draft = await showModalBottomSheet<_SessionDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SessionFormSheet(
        initial: session,
        day: session == null ? _selectedDay : null,
      ),
    );
    if (draft == null || !mounted) return;
    try {
      final api = ref.read(weddingEventApiProvider);
      if (session == null) {
        await api.create(
          wedding.id,
          CreateWeddingEventRequest(
            name: draft.name,
            type: draft.type,
            description: draft.description,
            eventDate: draft.date == null ? null : _isoDate(draft.date!),
            startTime: draft.start,
            endTime: draft.end,
            venueName: draft.venue,
            city: draft.city,
            displayOrder: _sessions.length,
          ),
        );
      } else {
        await api.update(wedding.id, session.id, {
          'name': draft.name,
          'type': draft.type.wireValue,
          if (draft.description != null) 'description': draft.description,
          if (draft.date != null) 'eventDate': _isoDate(draft.date!),
          if (draft.start != null) 'startTime': draft.start,
          if (draft.end != null) 'endTime': draft.end,
          if (draft.venue != null) 'venueName': draft.venue,
          if (draft.city != null) 'city': draft.city,
        });
      }
      if (!mounted) return;
      _toast(session == null ? 'Temps fort ajouté' : 'Temps fort modifié');
      await _load();
    } catch (_) {
      if (mounted) _toast('Enregistrement impossible');
    }
  }

  Future<void> _confirmDelete(WeddingEvent session) async {
    final wedding = _wedding;
    if (wedding == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce temps fort ?'),
        content: Text('« ${session.name} » sera retiré du programme.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(weddingEventApiProvider).delete(wedding.id, session.id);
      if (!mounted) return;
      _toast('Temps fort supprimé');
      await _load();
    } catch (_) {
      if (mounted) _toast('Suppression impossible');
    }
  }

  void _remind(WeddingEvent session) {
    _toast('Rappel programmé pour « ${session.name} »');
  }

  void _showDetails(WeddingEvent session) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name,
                style: AppTypography.cardTitle(
                  color: Theme.of(ctx).colorScheme.onSurface,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              _detailRow(
                Icons.category_outlined,
                'Type',
                _typeLabel(session.typeEnum),
              ),
              _detailRow(
                Icons.event_rounded,
                'Date',
                _longDate(_parseDate(session.eventDate)),
              ),
              _detailRow(
                Icons.schedule_rounded,
                'Horaire',
                _timeRange(session),
              ),
              if ((session.description ?? '').trim().isNotEmpty)
                _detailRow(
                  Icons.notes_rounded,
                  'Description',
                  session.description!.trim(),
                ),
              _detailRow(Icons.place_rounded, 'Lieu', _venueLine(session)),
              if ((session.venueAddress ?? '').trim().isNotEmpty)
                _detailRow(
                  Icons.signpost_outlined,
                  'Adresse',
                  session.venueAddress!.trim(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTypography.small(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.small(color: scheme.onSurface).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSessionMenu(WeddingEvent session) async {
    final auth = ref.read(authControllerProvider);
    final canUpdate = auth.hasPermission(PermissionCodes.eventUpdate);
    final canDelete = auth.hasPermission(PermissionCodes.eventDelete);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUpdate)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier l\'étape'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openSessionForm(session: session);
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Programmer un rappel'),
              onTap: () {
                Navigator.of(ctx).pop();
                _remind(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Voir les détails'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showDetails(session);
              },
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: OrganizerColors.danger,
                ),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: OrganizerColors.danger),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(session);
                },
              ),
          ],
        ),
      ),
    );
  }
  /// Feuille « Partager / exporter » : aperçu texte + copie.
  Future<void> _shareProgram() async {
    final text = _programAsText();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sheetScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partager le programme',
                  style: AppTypography.cardTitle(color: sheetScheme.onSurface)
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: sheetScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: AppTypography.small(
                        color: sheetScheme.onSurface,
                      ).copyWith(height: 1.45),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    if (mounted) _toast('Programme copié');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier le programme'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _programAsText() {
    final buffer = StringBuffer()
      ..writeln('Programme — ${_wedding?.displayName ?? ''}')
      ..writeln(
        '${_longDate(_selectedDay)}'
        '${_cityLabel().isEmpty ? '' : ' · ${_cityLabel()}'}',
      )
      ..writeln();
    final sessions = _visibleSessions;
    if (sessions.isEmpty) {
      buffer.writeln('Aucun temps fort programmé.');
    } else {
      for (final session in sessions) {
        buffer.writeln('• ${_formatTime(session.startTime)} — ${session.name}');
        final venue = _venueLine(session);
        if (venue.isNotEmpty) buffer.writeln('   $venue');
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _jumpToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
      helpText: 'Aller à une date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDay = _dateOnly(picked);
      _stripBase = _selectedDay.subtract(
        const Duration(days: _stripLength ~/ 2),
      );
    });
  }

  String _cityLabel() => (_wedding?.city ?? '').trim();

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  // --- Interface ----------------------------------------------------------

  Future<void> _openHeaderMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Partager le programme'),
              onTap: () {
                Navigator.of(ctx).pop();
                _shareProgram();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copier le programme'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(ClipboardData(text: _programAsText()));
                if (mounted) _toast('Programme copié');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Aller à une date'),
              onTap: () {
                Navigator.of(ctx).pop();
                _jumpToDate();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_rounded, size: 52, color: scheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_wedding == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 52, color: scheme.outline),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucun événement',
                style: AppTypography.cardTitle(color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Créez un événement pour planifier son programme.',
                textAlign: TextAlign.center,
                style: AppTypography.small(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: scheme.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 104),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _buildHeader(scheme),
              const SizedBox(height: AppSpacing.lg),
              _buildTitle(scheme),
              const SizedBox(height: AppSpacing.xl),
              _buildMonthRow(scheme),
              const SizedBox(height: AppSpacing.md),
              _buildDateStrip(scheme),
              const SizedBox(height: AppSpacing.xl),
              _buildFilterChips(scheme),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(scheme),
              const SizedBox(height: AppSpacing.lg),
              _buildTimeline(scheme),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(ColorScheme scheme) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _circleAction(
            scheme,
            icon: canPop
                ? Icons.arrow_back_ios_new_rounded
                : Icons.menu_rounded,
            onTap: () {
              if (canPop) {
                Navigator.of(context).pop();
              } else {
                _openHeaderMenu();
              }
            },
          ),
          const Spacer(),
          _circleAction(
            scheme,
            icon: Icons.ios_share_rounded,
            onTap: _shareProgram,
          ),
          const SizedBox(width: AppSpacing.sm),
          _circleAction(
            scheme,
            icon: Icons.calendar_month_rounded,
            onTap: _jumpToDate,
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => _openSessionForm(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Étape',
                    style: AppTypography.small(color: Colors.white).copyWith(
                      fontSize: 12.5,
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

  Widget _circleAction(
    ColorScheme scheme, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurface),
      ),
    );
  }
  Widget _buildTitle(ColorScheme scheme) {
    final city = _cityLabel();
    final badge = _isEventDay
        ? 'JOUR J${city.isEmpty ? '' : ' · ${city.toUpperCase()}'}'
        : (city.isEmpty ? 'PROGRAMME' : city.toUpperCase());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  badge,
                  style: AppTypography.small(color: scheme.primary).copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Programme & Calendrier',
            style: AppTypography.display(color: scheme.onSurface).copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _wedding?.displayName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small(
              color: scheme.onSurfaceVariant,
            ).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthRow(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Text(
            _monthLabel(_selectedDay).toUpperCase(),
            style: AppTypography.small(color: scheme.onSurfaceVariant).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _jumpToDate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voir mois',
                  style: AppTypography.small(color: scheme.primary).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDateStrip(ColorScheme scheme) {
    return SizedBox(
      height: 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            for (var i = 0; i < _stripLength; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == _stripLength - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: _DayChip(
                    day: _stripBase.add(Duration(days: i)),
                    selected: _sameDay(
                      _stripBase.add(Duration(days: i)),
                      _selectedDay,
                    ),
                    hasSessions: _hasSessionsOn(
                      _stripBase.add(Duration(days: i)),
                    ),
                    isEventDay: _sameDay(
                      _parseDate(_wedding?.eventDate),
                      _stripBase.add(Duration(days: i)),
                    ),
                    onTap: () => setState(
                      () => _selectedDay = _dateOnly(
                        _stripBase.add(Duration(days: i)),
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

  Widget _buildFilterChips(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          for (final filter in ProgramFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _filterChip(scheme, filter, isDark),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(
    ColorScheme scheme,
    ProgramFilter filter,
    bool isDark,
  ) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? OrganizerColors.darkText : OrganizerColors.lightText)
              : scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : scheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '${filter.label} (${_countOf(filter)})',
          style: AppTypography.small(
            color: selected
                ? (isDark
                      ? OrganizerColors.lightText
                      : OrganizerColors.lightSurface)
                : scheme.onSurface,
          ).copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
  Widget _buildSectionHeader(ColorScheme scheme) {
    final city = _cityLabel();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Programme du ${_longDate(_selectedDay)}'.toUpperCase(),
              maxLines: 2,
              style: AppTypography.small(color: scheme.onSurfaceVariant)
                  .copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Heure locale${city.isEmpty ? '' : ' $city'}'
            '\n${_utcOffsetLabel()}',
            textAlign: TextAlign.right,
            style: AppTypography.small(color: scheme.onSurfaceVariant)
                .copyWith(fontSize: 10, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme scheme) {
    if (_sessions.isEmpty) return _emptyProgram(scheme);
    final sessions = _visibleSessions;
    if (sessions.isEmpty) return _emptyDay(scheme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++)
            _TimelineRow(
              isFirst: i == 0,
              isLast: i == sessions.length - 1,
              child: _TimelineCard(
                session: sessions[i],
                status: _statusOf(sessions[i], i),
                typeLabel: _typeLabel(sessions[i].typeEnum),
                onTap: () => _showDetails(sessions[i]),
                onMenu: () => _showSessionMenu(sessions[i]),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _addMomentButton(scheme),
        ],
      ),
    );
  }

  Widget _addMomentButton(ColorScheme scheme) {
    return GestureDetector(
      onTap: () => _openSessionForm(),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ajouter un moment fort',
              style: AppTypography.small(color: scheme.primary).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyProgram(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          boxShadow: AppShadows.subtle(scheme.shadow),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note_rounded, size: 46, color: scheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun temps fort',
              style: AppTypography.cardTitle(color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez les étapes clés de votre événement : cérémonies, '
              'cocktail, dîner...',
              textAlign: TextAlign.center,
              style: AppTypography.small(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _openSessionForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un moment fort'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyDay(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(
              Icons.free_cancellation_rounded,
              size: 34,
              color: scheme.outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun temps fort pour ce filtre',
              style: AppTypography.small(
                color: scheme.onSurface,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Changez de filtre, choisissez un autre jour ou ajoutez une étape.',
              textAlign: TextAlign.center,
              style: AppTypography.small(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            _addMomentButton(scheme),
          ],
        ),
      ),
    );
  }
}

/// Style d'un statut d'étape du programme.
class _SessionStatus {
  const _SessionStatus({
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

/// Case d'un jour dans le bandeau horizontal.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.hasSessions,
    required this.isEventDay,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool hasSessions;
  final bool isEventDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [OrganizerColors.primaryDark, OrganizerColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : scheme.outline.withValues(alpha: 0.45),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: OrganizerColors.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayShort(day).toUpperCase(),
              style: AppTypography.small(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : scheme.onSurfaceVariant,
              ).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: AppTypography.cardTitle(
                color: selected ? Colors.white : scheme.onSurface,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            if (isEventDay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'JOUR J',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: selected ? Colors.white : scheme.primary,
                  ),
                ),
              )
            else
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSessions
                      ? (selected ? Colors.white : scheme.primary)
                      : Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de timeline : trait vertical + pastille carrée + carte.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.child,
    required this.isFirst,
    required this.isLast,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.outline.withValues(alpha: 0.45);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                SizedBox(
                  height: 18,
                  child: isFirst
                      ? null
                      : Center(child: Container(width: 2, color: lineColor)),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Center(child: Container(width: 2, color: lineColor)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Carte premium d'une étape du programme.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.session,
    required this.status,
    required this.typeLabel,
    required this.onTap,
    required this.onMenu,
  });

  final WeddingEvent session;
  final _SessionStatus status;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = (session.description ?? '').trim();
    final venue = _venueLine(session);
    final type = session.typeEnum;
    return GestureDetector(
      onTap: onTap,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _typeBackground(type),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _typeIcon(type),
                    size: 20,
                    color: _typeColor(type),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    session.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle(color: scheme.onSurface)
                        .copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                _badge(status),
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
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _timeRange(session),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.small(
                      color: scheme.onSurfaceVariant,
                    ).copyWith(fontSize: 11.5),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small(color: scheme.onSurfaceVariant)
                    .copyWith(fontSize: 11.5, height: 1.35),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.place_rounded, size: 13, color: scheme.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    venue.isEmpty ? 'Lieu à préciser' : venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.small(
                      color: scheme.onSurfaceVariant,
                    ).copyWith(fontSize: 11.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _typeBackground(type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: _typeColor(type),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _badge(_SessionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Utilitaires de date et de formatage ---------------------------------

/// Durée retenue pour une étape sans heure de fin (statut « en cours »).
const _fallbackSessionDuration = Duration(hours: 2);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Décalage horaire de l'appareil, ex. « UTC+02:00 ».
String _utcOffsetLabel() {
  final offset = DateTime.now().timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

DateTime? _parseDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : _dateOnly(parsed);
}

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

DateTime? _atTime(DateTime day, String? time) {
  final parts = (time ?? '').split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

String _isoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

const _weekdaysShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _weekdaysLong = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _monthsLong = [
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
const _monthsShort = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];

String _weekdayShort(DateTime day) => _weekdaysShort[day.weekday - 1];

String _monthLabel(DateTime day) => '${_monthsLong[day.month - 1]} ${day.year}';

String _longDate(DateTime? day) {
  if (day == null) return 'Date à définir';
  return '${_weekdaysLong[day.weekday - 1]} ${day.day} '
      '${_monthsShort[day.month - 1]} ${day.year}';
}

String _formatTime(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Horaire à définir';
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

String _durationLabel(WeddingEvent session) {
  final day = _parseDate(session.eventDate);
  final start = day == null ? null : _atTime(day, session.startTime);
  final end = day == null ? null : _atTime(day, session.endTime);
  if (start == null || end == null || !end.isAfter(start)) return '';
  final minutes = end.difference(start).inMinutes;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return 'durée ${rest}min';
  if (rest == 0) return 'durée ${hours}h';
  return 'durée ${hours}h${rest.toString().padLeft(2, '0')}';
}

String _timeRange(WeddingEvent session) {
  final start = session.startTime;
  final end = session.endTime;
  if ((start ?? '').isEmpty && (end ?? '').isEmpty) return 'Horaire à définir';
  final buffer = StringBuffer(_formatTime(start));
  if ((end ?? '').trim().isNotEmpty) buffer.write(' - ${_formatTime(end)}');
  final duration = _durationLabel(session);
  if (duration.isNotEmpty) buffer.write(' ($duration)');
  return buffer.toString();
}

String _venueLine(WeddingEvent session) {
  final venue = (session.venueName ?? '').trim();
  final city = (session.city ?? '').trim();
  if (venue.isNotEmpty && city.isNotEmpty) return '$venue · $city';
  if (venue.isNotEmpty) return venue;
  if (city.isNotEmpty) return city;
  return '';
}

String _typeLabel(WeddingEventType? type) => switch (type) {
  WeddingEventType.civilCeremony => 'Civil',
  WeddingEventType.religiousCeremony => 'Religieux',
  WeddingEventType.reception => 'Réception',
  WeddingEventType.afterParty => 'After-party',
  _ => 'Autre',
};

IconData _typeIcon(WeddingEventType? type) => switch (type) {
  WeddingEventType.civilCeremony => Icons.account_balance_rounded,
  WeddingEventType.religiousCeremony => Icons.church_rounded,
  WeddingEventType.reception => Icons.celebration_rounded,
  WeddingEventType.afterParty => Icons.nightlife_rounded,
  _ => Icons.event_rounded,
};

Color _typeColor(WeddingEventType? type) => switch (type) {
  WeddingEventType.civilCeremony => OrganizerColors.primary,
  WeddingEventType.religiousCeremony => OrganizerColors.info,
  WeddingEventType.reception => OrganizerColors.warning,
  WeddingEventType.afterParty => OrganizerColors.info,
  _ => OrganizerColors.muted,
};

Color _typeBackground(WeddingEventType? type) => switch (type) {
  WeddingEventType.civilCeremony => OrganizerColors.lightSurfaceViolet,
  WeddingEventType.religiousCeremony => OrganizerColors.infoBg,
  WeddingEventType.reception => OrganizerColors.warningBg,
  WeddingEventType.afterParty => OrganizerColors.infoBg,
  _ => OrganizerColors.mutedBg,
};

TimeOfDay? _parseTimeOfDay(String? raw) {
  final parts = (raw ?? '').split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Données saisies dans le formulaire d'étape.
class _SessionDraft {
  const _SessionDraft({
    required this.name,
    required this.type,
    this.description,
    this.date,
    this.start,
    this.end,
    this.venue,
    this.city,
  });

  final String name;
  final WeddingEventType type;
  final String? description;
  final DateTime? date;
  final String? start;
  final String? end;
  final String? venue;
  final String? city;
}
/// Feuille « + Étape » : création ou modification d'un temps fort.
class _SessionFormSheet extends StatefulWidget {
  const _SessionFormSheet({this.initial, this.day});

  final WeddingEvent? initial;
  final DateTime? day;

  @override
  State<_SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends State<_SessionFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _venue;
  late final TextEditingController _city;
  late final TextEditingController _description;

  late WeddingEventType _type;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _venue = TextEditingController(text: initial?.venueName ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _type = initial?.typeEnum ?? WeddingEventType.civilCeremony;
    _date = _parseDate(initial?.eventDate) ?? widget.day ?? _dateOnly(DateTime.now());
    _start = _parseTimeOfDay(initial?.startTime);
    _end = _parseTimeOfDay(initial?.endTime);
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
      helpText: 'Date de l\'étape',
    );
    if (picked != null) setState(() => _date = _dateOnly(picked));
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (start ? _start : _end) ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: start ? 'Heure de début' : 'Heure de fin',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Le nom de l\'étape est requis');
      return;
    }
    Navigator.of(context).pop(
      _SessionDraft(
        name: name,
        type: _type,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        date: _date,
        start: _start == null ? null : _formatTimeOfDay(_start!),
        end: _end == null ? null : _formatTimeOfDay(_end!),
        venue: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initial == null
                  ? 'Nouveau temps fort'
                  : 'Modifier l\'étape',
              style: AppTypography.cardTitle(color: scheme.onSurface).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label(scheme, 'Nom de l\'étape'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Cérémonie civile, Cocktail...',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _label(scheme, 'Type d\'étape'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final type in WeddingEventType.values)
                  GestureDetector(
                    onTap: () => setState(() => _type = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _type == type
                            ? _typeBackground(type)
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _type == type
                              ? _typeColor(type)
                              : scheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _type == type
                              ? _typeColor(type)
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label(scheme, 'Date'),
            _tappable(
              scheme,
              icon: Icons.event_rounded,
              text: _longDate(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(scheme, 'Début'),
                      _tappable(
                        scheme,
                        icon: Icons.schedule_rounded,
                        text: _start == null
                            ? 'Choisir'
                            : _formatTimeOfDay(_start!),
                        onTap: () => _pickTime(start: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(scheme, 'Fin (optionnel)'),
                      _tappable(
                        scheme,
                        icon: Icons.schedule_rounded,
                        text: _end == null ? 'Choisir' : _formatTimeOfDay(_end!),
                        onTap: () => _pickTime(start: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label(scheme, 'Lieu'),
            TextField(
              controller: _venue,
              decoration: const InputDecoration(
                hintText: 'Salle Majestic Pullman',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _label(scheme, 'Ville'),
            TextField(
              controller: _city,
              decoration: const InputDecoration(hintText: 'Kinshasa'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label(scheme, 'Notes (optionnel)'),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Bénédiction nuptiale, échange des alliances...',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _submit,
              child: Text(
                widget.initial == null ? 'Ajouter l\'étape' : 'Enregistrer',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.small(color: scheme.onSurfaceVariant).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tappable(
    ColorScheme scheme, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  color: scheme.onSurface,
                ).copyWith(fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}