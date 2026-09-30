import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/theme/gi_ui.dart';
import '../../organisateur/invitations/screens/invitation_create_screen.dart';
import '../../organisateur/invitations/screens/invitations_list_screen.dart';
import '../widgets/gi_modules.dart';
import '../widgets/gi_nav.dart';
import 'gi_dashboard_tab.dart';
import 'gi_categories_screen.dart';
import 'gi_guest_form_screen.dart';
import 'gi_guests_view.dart';
import 'gi_profile_screen.dart';
import 'gi_qr_codes_screen.dart';
import 'gi_rsvp_screen.dart';

/// Shell du rôle GESTIONNAIRE_INVITES : dashboard + navigation basse.
class GestionnaireInvitesHomeScreen extends ConsumerStatefulWidget {
  const GestionnaireInvitesHomeScreen({super.key});

  @override
  ConsumerState<GestionnaireInvitesHomeScreen> createState() =>
      _GestionnaireInvitesHomeScreenState();
}

class _GestionnaireInvitesHomeScreenState
    extends ConsumerState<GestionnaireInvitesHomeScreen> {
  GiTab _tab = GiTab.home;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _onSelect(GiTab tab) {
    switch (tab) {
      case GiTab.add:
        // Bouton + contextuel : Nouvel invité sur l'onglet Invités, sinon invitation.
        if (_tab == GiTab.guests) {
          _addGuest();
        } else {
          _open(const InvitationCreateScreen());
        }
        break;
      case GiTab.invitations:
        _open(const InvitationsListScreen());
        break;
      case GiTab.more:
        _open(const GiProfileScreen());
        break;
      default:
        setState(() => _tab = tab);
    }
  }

  void _openModule(int index) {
    switch (index) {
      case 0:
        setState(() => _tab = GiTab.guests);
        break;
      case 1:
        _open(const InvitationsListScreen());
        break;
      case 2:
        _open(const GiRsvpScreen());
        break;
      case 3:
        _open(const GiCategoriesScreen());
        break;
      case 4:
        _open(const GiQrCodesScreen());
        break;
      case 5:
        _open(const GiProfileScreen());
        break;
      default:
        break;
    }
  }

  void _addGuest() => _open(const GiGuestFormScreen());

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: IndexedStack(index: _tab.index, children: [
          GiDashboardTab(onOpenModule: _openModule),
          GiGuestsView(onAddGuest: _addGuest),
          const SizedBox.shrink(),
          const SizedBox.shrink(),
          GiMoreTab(onProfile: () => _open(const GiProfileScreen())),
        ]),
      ),
      bottomNavigationBar: GiBottomNav(current: _tab, onSelect: _onSelect),
    );
  }
}