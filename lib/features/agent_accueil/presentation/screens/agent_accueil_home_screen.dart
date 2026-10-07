import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/event_media/event_media_providers.dart';
import '../../../../src/theme/app_colors.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../widgets/agent_bottom_navigation.dart';
import '../widgets/agent_header.dart';
import '../widgets/guest_search_bar.dart';
import '../widgets/scanner_action_card.dart';
import 'agent_attendance_screen.dart';
import 'agent_profile_screen.dart';
import 'qr_scanner_screen.dart';

class AgentAccueilHomeScreen extends ConsumerStatefulWidget {
  const AgentAccueilHomeScreen({super.key});

  @override
  ConsumerState<AgentAccueilHomeScreen> createState() =>
      _AgentAccueilHomeScreenState();
}

class _AgentAccueilHomeScreenState
    extends ConsumerState<AgentAccueilHomeScreen> {
  AgentTab _tab = AgentTab.home;

  List<Wedding> _weddings = const [];
  Dashboard? _dashboard;
  bool _loading = true;

  String? _statsError;
  int? _presentFallback;
  int? _selectedWeddingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _statsError = null;
    });

    final storage = const FlutterSecureStorage();

    List<Wedding> weddings;
    try {
      weddings = await ref.read(weddingApiProvider).list(size: 25);
      weddings = [...weddings]..sort((a, b) => (a.displayOrder ?? 999).compareTo(b.displayOrder ?? 999));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weddings = const [];
        _dashboard = null;
        _presentFallback = null;
        _statsError = 'Impossible de charger les événements.';
        _loading = false;
      });
      return;
    }

    final storedSelected = int.tryParse((await storage.read(key: 'selected_wedding_id')) ?? '');
    if (storedSelected != null && storedSelected > 0 && weddings.any((w) => w.id == storedSelected)) {
      _selectedWeddingId = storedSelected;
    } else if (weddings.isNotEmpty) {
      _selectedWeddingId = weddings.first.id;
    } else {
      _selectedWeddingId = null;
    }

    Dashboard? dash;
    int? presentFallback;
    String? statsError;

    if (_selectedWeddingId != null) {
      try {
        dash = await ref.read(dashboardApiProvider).getForWedding(_selectedWeddingId!);
      } catch (error) {
        try {
          final present = await ref
              .read(checkInApiProvider)
              .listPresent(_selectedWeddingId!);
          presentFallback = present.fold<int>(
            0,
            (sum, person) => sum + person.numberOfAttendees,
          );
          statsError = _statsMessage(error, hasPresentFallback: true);
        } catch (_) {
          statsError = _statsMessage(error, hasPresentFallback: false);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _weddings = weddings;
      _dashboard = dash;
      _presentFallback = presentFallback;
      _statsError = statsError;
      _loading = false;
    });
  }

  Future<void> _selectWedding(int weddingId) async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'selected_wedding_id', value: weddingId.toString());
    setState(() {
      _selectedWeddingId = weddingId;
      _dashboard = null;
      _presentFallback = null;
      _statsError = null;
    });
    await _loadStats(weddingId);
  }

  Future<void> _loadStats(int weddingId) async {
    try {
      final dash = await ref.read(dashboardApiProvider).getForWedding(weddingId);
      if (!mounted) return;
      setState(() {
        _dashboard = dash;
      });
    } catch (error) {
      try {
        final present = await ref
            .read(checkInApiProvider)
            .listPresent(weddingId);
        if (!mounted) return;
        setState(() {
          _presentFallback = present.fold<int>(
            0,
            (sum, person) => sum + person.numberOfAttendees,
          );
          _statsError = _statsMessage(error, hasPresentFallback: true);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _statsError = _statsMessage(error, hasPresentFallback: false);
        });
      }
    }
  }

  String _statsMessage(Object error, {required bool hasPresentFallback}) {
    final denied = error is DioException && error.response?.statusCode == 403;
    if (denied) {
      return hasPresentFallback
          ? 'Invités attendus indisponibles : votre rôle n’a pas accès au tableau de bord (DASHBOARD_VIEW).'
          : 'Statistiques indisponibles : votre rôle n’a pas accès au tableau de bord (DASHBOARD_VIEW).';
    }
    return hasPresentFallback
        ? 'Invités attendus indisponibles : tableau de bord injoignable.'
        : 'Statistiques indisponibles pour le moment.';
  }

  void _openScanner() {
    int? weddingId = _selectedWeddingId;
    if (weddingId == null || weddingId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun événement assigné pour le scan')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrScannerScreen(weddingId: weddingId),
      ),
    );
  }

  void _onTab(AgentTab tab) {
    if (tab == AgentTab.scanner) {
      _openScanner();
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.firstName ?? '').trim();
    final displayName = firstName.isNotEmpty ? firstName : 'Agent';

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: p.primary))
            : IndexedStack(
                index: _tab.index,
                children: [
                  _buildHome(displayName, p),
                  _GuestsPlaceholder(
                    weddingId: _selectedWeddingId ?? 0,
                    onBack: () => setState(() => _tab = AgentTab.home),
                  ),
                  const SizedBox.shrink(),
                  AgentAttendanceScreen(
                    weddingId: _selectedWeddingId ?? 0,
                  ),
                  const AgentProfileScreen(),
                ],
              ),
      ),
      bottomNavigationBar: AgentBottomNavigation(
        current: _tab,
        onSelect: _onTab,
      ),
    );
  }

  Widget _buildHome(String firstName, AgentPalette p) {
    final attendance = _dashboard?.attendance;

    final expectedAttendees = attendance?.expected ?? _dashboard?.guests.total;
    final presentAttendees = attendance?.checkedIn ?? _presentFallback;
    final remainingAttendees = attendance?.remaining;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AgentHeader(
            firstName: firstName,
            onNotificationsTap: () {},
            onProfileTap: () => setState(() => _tab = AgentTab.profile),
          ),
          const SizedBox(height: 18),
          if (_weddings.isNotEmpty)
            _WeddingSelector(
              weddings: _weddings,
              selectedId: _selectedWeddingId ?? _weddings.first.id,
              onSelected: _selectWedding,
            )
          else
            _EmptyEventCard(p: p),
          const SizedBox(height: 20),
          ScannerActionCard(onTap: _openScanner),
          const SizedBox(height: 20),
          if (_statsError != null) ...[
            _StatsWarning(message: _statsError!),
            const SizedBox(height: 16),
          ],
          Column(
            children: [
              _MiniStat(
                icon: Icons.group_outlined,
                label: 'Invités attendus',
                value: expectedAttendees == null ? '—' : '$expectedAttendees',
                accent: p.primary,
              ),
              const SizedBox(height: 12),
              _MiniStat(
                icon: Icons.check_circle_outlined,
                label: 'Présents',
                value: presentAttendees == null ? '—' : '$presentAttendees',
                accent: AppColors.success,
              ),
              if (remainingAttendees != null) ...[
                const SizedBox(height: 12),
                _MiniStat(
                  icon: Icons.hourglass_empty_outlined,
                  label: 'Restants',
                  value: '$remainingAttendees',
                  accent: AppColors.agentGold,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _AttendanceProgress(attendance: attendance, palette: p),
          const SizedBox(height: 18),
          GuestSearchBar(
            onTap: () => setState(() => _tab = AgentTab.guests),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _EmptyEventCard extends StatelessWidget {
  const _EmptyEventCard({required this.p});

  final AgentPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: p.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucun événement assigné pour le moment.',
              style: TextStyle(color: p.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeddingSelector extends StatelessWidget {
  const _WeddingSelector({
    required this.weddings,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Wedding> weddings;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    Wedding? selected;
    try {
      selected = weddings.firstWhere((w) => w.id == selectedId);
    } catch (_) {
      selected = weddings.isNotEmpty ? weddings.first : null;
    }
    final label = selected?.displayName.isNotEmpty == true ? selected!.displayName : 'Événement';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: p.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.swap_vert_rounded, color: p.textSecondary, size: 20),
            onSelected: onSelected,
            itemBuilder: (context) => [
              for (final w in weddings)
                PopupMenuItem(
                  value: w.id,
                  child: Text(
                    w.displayName.isNotEmpty ? w.displayName : 'Événement ${w.id}',
                    style: TextStyle(
                      color: w.id == selectedId ? p.primary : p.textPrimary,
                      fontWeight: w.id == selectedId ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  const _AttendanceProgress({required this.attendance, required this.palette});

  final AttendanceStats? attendance;
  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    if (attendance == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(Icons.insights_outlined, color: p.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Progression des arrivées indisponible pour votre rôle.',
                style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final expected = attendance!.expected;
    final checkedIn = attendance!.checkedIn;
    final rate = expected == 0 ? 0.0 : (checkedIn / expected).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.insights_outlined, color: p.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression des arrivées',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$checkedIn sur $expected enregistrés',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(rate * 100).round()}%',
                  style: TextStyle(
                    color: p.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: p.border,
              color: p.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Présents : $checkedIn',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Restants : ${attendance!.remaining}',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsWarning extends StatelessWidget {
  const _StatsWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: p.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: p.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestsPlaceholder extends ConsumerStatefulWidget {
  const _GuestsPlaceholder({required this.weddingId, required this.onBack});

  final int weddingId;
  final VoidCallback onBack;

  @override
  ConsumerState<_GuestsPlaceholder> createState() => _GuestsPlaceholderState();
}

class _GuestsPlaceholderState extends ConsumerState<_GuestsPlaceholder> {
  final _query = TextEditingController();
  List<CheckInSearchHit> _hits = const [];
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (widget.weddingId == 0 || q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final hits = await ref
          .read(checkInApiProvider)
          .searchGuests(widget.weddingId, q);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _openCard(String token) async {
    try {
      final bytes = await ref.read(eventMediaApiProvider).publicCard(token);
      final file = File('${Directory.systemTemp.path}/carte-$token.jpg');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carte enregistrée : ${file.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Carte indisponible')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(Icons.arrow_back, color: p.textPrimary),
              ),
              Expanded(
                child: Text(
                  'Recherche invité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _query,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nom ou téléphone',
              prefixIcon: Icon(Icons.search, color: p.textSecondary),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: p.primary),
              ),
            ),
            onSubmitted: _search,
          ),
        ),
        if (_searching) LinearProgressIndicator(color: p.primary),
        Expanded(
          child: ListView(
            children: [
              for (final hit in _hits)
                ListTile(
                  title: Text(
                    hit.guestName,
                    style: TextStyle(color: p.textPrimary),
                  ),
                  subtitle: Text(
                    [
                      if (hit.tableName != null) hit.tableName!,
                      hit.canCheckIn ? 'Peut entrer' : 'Déjà traité',
                    ].join(' · '),
                    style: TextStyle(color: p.textSecondary),
                  ),
                  trailing: hit.publicToken == null
                      ? null
                      : IconButton(
                          tooltip: 'Carte',
                          icon: Icon(
                            Icons.image_outlined,
                            color: p.textSecondary,
                          ),
                          onPressed: () => _openCard(hit.publicToken!),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
