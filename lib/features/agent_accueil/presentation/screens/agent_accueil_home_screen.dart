import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
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
      if (weddings.isNotEmpty) {
        dash = await ref.read(dashboardApiProvider).getForWedding(weddings.first.id);
      }
      if (!mounted) return;
      setState(() {
        _weddings = weddings;
        _dashboard = dash;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onTab(AgentTab tab) {
    if (tab == AgentTab.scanner) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()),
      );
      return;
    }
    setState(() => _tab = tab);
  }
@override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final rawFirstName = user?.firstName ?? '';
    final firstName = rawFirstName.isNotEmpty ? rawFirstName : 'Invité';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _tab.index,
                children: [
                  _buildHome(firstName),
                  _GuestsPlaceholder(onBack: () => setState(() => _tab = AgentTab.home)),
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

  Widget _buildHome(String firstName) {
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()),
              ),
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
              items: const [],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GuestsPlaceholder extends StatelessWidget {
  const _GuestsPlaceholder({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Center(child: Text('Invités (à venir)'));
}