import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/app_organizer_bottom_nav.dart';
import 'calendrier_onglet.dart';
import 'evenement_create_stepper_screen.dart';
import 'guests_management_screen.dart';
import 'mes_evenements_screen.dart';
import 'organisateur_plus_tab.dart';

class OrganisateurHomeScreen extends ConsumerStatefulWidget {
  const OrganisateurHomeScreen({super.key});

  @override
  ConsumerState<OrganisateurHomeScreen> createState() =>
      _OrganisateurHomeScreenState();
}

class _OrganisateurHomeScreenState
    extends ConsumerState<OrganisateurHomeScreen> {
  OrganizerTab _tab = OrganizerTab.home;
  int? _selectedWeddingId;
  List<Wedding> _weddings = const [];

  @override
  void initState() {
    super.initState();
    _loadWeddings();
  }

  Future<void> _loadWeddings() async {
    try {
      final events = await ref.read(weddingApiProvider).list(size: 25);
      if (!mounted) return;
      setState(() {
        _weddings = events;
        if (_selectedWeddingId == null && events.isNotEmpty) {
          _selectedWeddingId = events.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_weddings.isNotEmpty)
              _WeddingSelector(
                weddings: _weddings,
                selectedId: _selectedWeddingId ?? _weddings.first.id,
                onSelected: (id) {
                  setState(() => _selectedWeddingId = id);
                },
              ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  const MesEvenementsScreen(embedded: true),
                  _GuestsTab(
                    weddingId: _selectedWeddingId,
                    onBack: () => setState(() => _tab = OrganizerTab.home),
                  ),
                  const SizedBox.shrink(),
                  const CalendrierOnglet(),
                  const OrganizerMoreTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppOrganizerBottomNav(
        current: _tab,
        onSelect: _onSelect,
      ),
    );
  }

  void _onSelect(OrganizerTab tab) {
    if (tab == OrganizerTab.add) {
      _openCreate();
      return;
    }
    setState(() => _tab = tab);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const EvenementCreateStepperScreen(),
      ),
    );
    if (created == true) {
      ref.read(weddingListRevisionProvider.notifier).bump();
    }
  }
}


class _GuestsTab extends ConsumerStatefulWidget {
  const _GuestsTab({this.weddingId, required this.onBack});

  final int? weddingId;

  final VoidCallback onBack;

  @override
  ConsumerState<_GuestsTab> createState() => _GuestsTabState();
}

class _GuestsTabState extends ConsumerState<_GuestsTab> {
  int? _weddingId;
  bool _loading = true;
  String? _error;
  bool _hasEvents = false;

  @override
  void initState() {
    super.initState();
    _weddingId = widget.weddingId;
    if (_weddingId == null) {
      _loadWedding();
    } else {
      _hasEvents = true;
      _loading = false;
    }
  }

  Future<void> _loadWedding() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(weddingApiProvider);
      final events = await api.list(size: 1);
      if (!mounted) return;
      setState(() {
        _weddingId = events.isNotEmpty ? events.first.id : null;
        _hasEvents = events.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos événements';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppErrorState(
        title: 'Impossible de charger vos événements',
        message: 'Vérifiez votre connexion puis réessayez.',
        onRetry: _loadWedding,
      );
    }
    if (_weddingId == null || !_hasEvents) {
      return const AppEmptyState(
        icon: Icons.group_off_outlined,
        title: 'Aucun événement',
        message:
            'Créez d\u2019abord un événement pour gérer vos invités.',
      );
    }
    return GuestsManagementScreen(
      weddingId: _weddingId!,
      onBack: widget.onBack,
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
    final scheme = Theme.of(context).colorScheme;
    Wedding? selected;
    try {
      selected = weddings.firstWhere((w) => w.id == selectedId);
    } catch (_) {
      selected = weddings.isNotEmpty ? weddings.first : null;
    }
    if (selected == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected.displayName.isNotEmpty ? selected.displayName : 'Événement',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.swap_vert_rounded, color: scheme.onSurfaceVariant, size: 20),
            onSelected: onSelected,
            itemBuilder: (context) => [
              for (final w in weddings)
                PopupMenuItem(
                  value: w.id,
                  child: Text(
                    w.displayName.isNotEmpty ? w.displayName : 'Événement ${w.id}',
                    style: TextStyle(
                      color: w.id == selectedId ? scheme.primary : scheme.onSurface,
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

