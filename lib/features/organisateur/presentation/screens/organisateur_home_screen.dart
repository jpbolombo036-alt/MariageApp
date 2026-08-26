import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/wedding/wedding_providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/app_organizer_bottom_nav.dart';
import 'calendrier_onglet.dart';
import 'evenement_create_stepper_screen.dart';
import 'invites_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: [
          const MesEvenementsScreen(embedded: true),
          const _GuestsTab(),
          const SizedBox.shrink(),
          const CalendrierOnglet(),
          const OrganizerMoreTab(),
        ],
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

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EvenementCreateStepperScreen(),
      ),
    );
  }
}


class _GuestsTab extends ConsumerStatefulWidget {
  const _GuestsTab();

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
    _loadWedding();
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
    return OrganisateurGuestsScreen(weddingId: _weddingId!);
  }
}

