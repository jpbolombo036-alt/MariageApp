import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/event_media/event_media_providers.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/theme/app_colors.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../widgets/agent_bottom_navigation.dart';
import '../widgets/agent_header.dart';
import '../widgets/attendance_stat_card.dart';
import '../widgets/event_card.dart';
import '../widgets/guest_search_bar.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/scanner_action_card.dart';
import 'agent_attendance_screen.dart';
import 'agent_profile_screen.dart';
import 'qr_scanner_screen.dart';

/// Écran principal de l'espace AGENT_ACCUEIL.
/// Réservé (via le routeur) aux utilisateurs ayant le rôle AGENT_ACCUEIL.
class AgentAccueilHomeScreen extends ConsumerStatefulWidget {
  const AgentAccueilHomeScreen({super.key});

  @override
  ConsumerState<AgentAccueilHomeScreen> createState() =>
      _AgentAccueilHomeScreenState();
}

class _AgentAccueilHomeScreenState extends ConsumerState<AgentAccueilHomeScreen> {
  AgentTab _tab = AgentTab.home;

  List<Wedding> _weddings = const [];
  Dashboard? _dashboard;
  List<ActivityItem> _activity = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final weddings = await ref.read(weddingApiProvider).list(size: 25);
      Dashboard? dash;
      List<ActivityItem> activity = const [];
      if (weddings.isNotEmpty) {
        dash = await ref.read(dashboardApiProvider).getForWedding(weddings.first.id);
        try {
          activity = await ref.read(dashboardApiProvider).recentActivity(weddings.first.id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _weddings = weddings;
        _dashboard = dash;
        _activity = activity;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openScanner() {
    if (_weddings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun événement assigné pour le scan')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrScannerScreen(weddingId: _weddings.first.id),
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
    final rawFirstName = user?.firstName ?? '';
    final firstName = rawFirstName.isNotEmpty ? rawFirstName : 'Invité';

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: p.primary))
            : IndexedStack(
                index: _tab.index,
                children: [
                  _buildHome(firstName, p),
                  _GuestsPlaceholder(
                    weddingId: _weddings.isEmpty ? 0 : _weddings.first.id,
                    onBack: () => setState(() => _tab = AgentTab.home),
                  ),
                  const SizedBox.shrink(),
                  AgentAttendanceScreen(
                    weddingId: _weddings.isEmpty ? 0 : _weddings.first.id,
                  ),
                  const AgentProfileScreen(),
                ],
              ),
      ),
      bottomNavigationBar: AgentBottomNavigation(current: _tab, onSelect: _onTab),
    );
  }

  Widget _buildHome(String firstName, AgentPalette p) {
    final wedding = _weddings.isNotEmpty ? _weddings.first : null;
    final guests = _dashboard?.guests;
    final attendance = _dashboard?.attendance;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AgentHeader(
            firstName: firstName,
            onNotificationsTap: () {},
            onProfileTap: () => setState(() => _tab = AgentTab.profile),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: EventCard(
              eventName: wedding?.displayName,
              venue: wedding?.welcomeMessage,
              dateLabel: wedding?.description,
              isActive: wedding?.status == 'PUBLISHED',
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ScannerActionCard(
              onTap: _openScanner,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AttendanceStatCard(
                  icon: Icons.group_outlined,
                  value: '${guests?.total ?? 0}',
                  label: 'Invités attendus',
                ),
                const SizedBox(width: 14),
                AttendanceStatCard(
                  icon: Icons.check_circle_outline,
                  value: '${attendance?.checkedIn ?? 0}',
                  label: 'Invités présents',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GuestSearchBar(
              onTap: () => setState(() => _tab = AgentTab.guests),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RecentActivitySection(
              title: 'Activité récente',
              onSeeAll: () => setState(() => _tab = AgentTab.attendance),
              items: [
                for (final item in _activity)
                  RecentActivityItem(
                    guestName: (item.details != null && item.details!.isNotEmpty)
                        ? item.details!
                        : item.action,
                    subtitle: item.action,
                    time: item.performedAt,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
      final hits = await ref.read(checkInApiProvider).searchGuests(widget.weddingId, q);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte indisponible')),
      );
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
              IconButton(onPressed: widget.onBack, icon: Icon(Icons.arrow_back, color: p.textPrimary)),
              Expanded(
                child: Text(
                  'Recherche invité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary),
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
              border: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: p.primary)),
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
                  title: Text(hit.guestName, style: TextStyle(color: p.textPrimary)),
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
                          icon: Icon(Icons.image_outlined, color: p.textSecondary),
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