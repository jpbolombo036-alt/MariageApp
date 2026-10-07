import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class _AgentAccueilHomeScreenState
    extends ConsumerState<AgentAccueilHomeScreen> {
  AgentTab _tab = AgentTab.home;

  List<Wedding> _weddings = const [];
  Dashboard? _dashboard;
  bool _loading = true;

  /// Message affiché quand les statistiques n'ont pas pu être chargées.
  String? _statsError;

  /// Personnes présentes calculées via le module check-in, utilisé comme repli
  /// lorsque le tableau de bord est inaccessible (AGENT_ACCUEIL n'a pas la
  /// permission `DASHBOARD_VIEW`).
  int? _presentFallback;

  /// Dernier weddingId utilisé avec succès pour un scan — persisté pour permettre
  /// de scanner hors ligne même si la liste des événements n'est pas chargeable.
  int? _lastScannedWeddingId;

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
    _lastScannedWeddingId = int.tryParse((await storage.read(key: 'last_wedding_id')) ?? '');

    // 1) Événements. Chargés séparément pour être **conservés** même si la
    //    suite échoue : auparavant, une erreur du tableau de bord faisait
    //    sauter le setState final et laissait `_weddings` vide (écran vide).
    List<Wedding> weddings;
    try {
      weddings = await ref.read(weddingApiProvider).list(size: 25);
      if (weddings.isNotEmpty) {
        await storage.write(key: 'last_wedding_id', value: weddings.first.id.toString());
      }
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

    // 2) Statistiques. `GET /api/events/{id}/dashboard` exige la permission
    //    DASHBOARD_VIEW, absente du rôle AGENT_ACCUEIL → 403 possible. On ne
    //    fait pas échouer l'écran et on alimente les présences par un repli
    //    autorisé pour l'agent (`GET /api/checkins/event/{id}`).
    Dashboard? dash;
    int? presentFallback;
    String? statsError;

    if (weddings.isNotEmpty) {
      final weddingId = weddings.first.id;
      try {
        dash = await ref.read(dashboardApiProvider).getForWedding(weddingId);
      } catch (error) {
        try {
          final present = await ref
              .read(checkInApiProvider)
              .listPresent(weddingId);
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

  /// Message lisible selon la cause de l'échec du tableau de bord.
  String _statsMessage(Object error, {required bool hasPresentFallback}) {
    final denied = error is DioException && error.response?.statusCode == 403;
    if (denied) {
      return hasPresentFallback
          ? 'Invités attendus indisponibles : votre rôle n’a pas accès au '
              'tableau de bord (DASHBOARD_VIEW).'
          : 'Statistiques indisponibles : votre rôle n’a pas accès au tableau '
              'de bord (DASHBOARD_VIEW).';
    }
    return hasPresentFallback
        ? 'Invités attendus indisponibles : tableau de bord injoignable.'
        : 'Statistiques indisponibles pour le moment.';
  }

  void _openScanner() {
    int? weddingId;
    if (_weddings.isNotEmpty) {
      weddingId = _weddings.first.id;
    } else {
      weddingId = _lastScannedWeddingId;
    }
    if (weddingId == null || weddingId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun événement assigné pour le scan')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrScannerScreen(weddingId: weddingId!),
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
      bottomNavigationBar: AgentBottomNavigation(
        current: _tab,
        onSelect: _onTab,
      ),
    );
  }

  Widget _buildHome(String firstName, AgentPalette p) {
    final wedding = _weddings.isNotEmpty ? _weddings.first : null;
    final attendance = _dashboard?.attendance;

    final expectedAttendees = attendance?.expected ?? _dashboard?.guests.total;
    final presentAttendees = attendance?.checkedIn ?? _presentFallback;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AgentHeader(
            firstName: firstName,
            onNotificationsTap: () {},
            onProfileTap: () => setState(() => _tab = AgentTab.profile),
          ),
          const SizedBox(height: 22),
          EventCard(
            eventName: wedding?.displayName,
            venue: wedding?.welcomeMessage,
            dateLabel: wedding?.description,
            isActive: wedding?.status == 'PUBLISHED',
          ),
          const SizedBox(height: 20),
          ScannerActionCard(onTap: _openScanner),
          const SizedBox(height: 18),
          if (_statsError != null) ...[
            _StatsWarning(message: _statsError!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: AttendanceStatCard(
                  icon: Icons.group_outlined,
                  value: expectedAttendees == null ? '—' : '$expectedAttendees',
                  label: 'Invités attendus',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AttendanceStatCard(
                  icon: Icons.check_circle_outline,
                  value: presentAttendees == null ? '—' : '$presentAttendees',
                  label: 'Invités présents',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAttendanceOverview(attendance, p),
          const SizedBox(height: 18),
          GuestSearchBar(
            onTap: () => setState(() => _tab = AgentTab.guests),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget _buildAttendanceOverview(AttendanceStats? attendance, AgentPalette p) {
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
              style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
  final expected = attendance.expected;
  final checkedIn = attendance.checkedIn;
  final rate = expected == 0
      ? 0.0
      : (checkedIn / expected).clamp(0.0, 1.0).toDouble();
  return Container(
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.insights_outlined, color: p.primary, size: 20),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 2),
                  Text(
                    '$checkedIn sur $expected invités enregistrés',
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${(rate * 100).round()}%',
              style: TextStyle(
                color: p.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 10,
            backgroundColor: p.border,
            color: p.primary,
          ),
        ),
        const SizedBox(height: 12),
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
              'Restants : ${attendance.remaining}',
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

/// Bandeau d'information : statistiques partiellement indisponibles.
class _StatsWarning extends StatelessWidget {
  const _StatsWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: p.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
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
