import 'package:flutter/material.dart';

import '../../../src/guest/guest_api.dart';
import '../../../src/rsvp/rsvp_api.dart';
import '../../../src/theme/gi_ui.dart';
import '../widgets/gi_nav.dart';
import '../widgets/guest_tiles.dart';
import 'gi_guest_form_screen.dart';

/// Ligne d'information du détail invité (icône + libellé + valeur/badge).
class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    this.value,
    this.widget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: p.primary),
          const SizedBox(width: 12),
          SizedBox(
              width: 150,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 12, color: p.textSecondary))),
          const Spacer(),
          widget ??
              Flexible(
                child: Text(value ?? '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, color: p.textPrimary)),
              ),
        ],
      ),
    );
  }
}
/// Écran « Détails de l'invité » (rôle GESTIONNAIRE_INVITES).
class GiGuestDetailScreen extends StatelessWidget {
  const GiGuestDetailScreen({super.key, required this.guest, this.rsvp});

  final Guest guest;
  final GuestRsvp? rsvp;

  String get _initial {
    final n = '${guest.firstName} ${guest.lastName}'.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20, color: p.textPrimary)),
        title: Text('Détails de l\u2019invité',
            style: TextStyle(color: p.textPrimary)),
        actions: [
          PopupMenuButton<String>(
            icon:
                Icon(Icons.more_vert, size: 22, color: p.textPrimary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GiGuestFormScreen(edit: guest)));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'edit',
                  child: Text('Modifier l\u2019invité', style: TextStyle(fontSize: 13))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _profileCard(context, p),
          const SizedBox(height: 20),
          Text('Informations',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(height: 8),
          _infoSection(context, p),
          const SizedBox(height: 24),
          GiPrimaryButton(
            label: 'Modifier l\u2019invité',
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GiGuestFormScreen(edit: guest))),
          ),
        ]),
      ),
    );
  }

  Widget _profileCard(BuildContext context, GiPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GiRadius.card),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
         CircleAvatar(radius: 28,
             backgroundColor: p.primaryLightBg,
             child: Text(_initial,
                 style: TextStyle(
                     fontSize: 20,
                     fontWeight: FontWeight.w700,
                     color: p.primary))),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${guest.firstName} ${guest.lastName}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            if ((guest.email ?? '').isNotEmpty) ...[
              SizedBox(height: 2),
              Row(children: [
                Icon(Icons.mail_outline, size: 13, color: p.textSecondary),
                SizedBox(width: 6),
                Expanded(child: Text(guest.email!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textSecondary))),
              ]),
            ],
            if ((guest.phone ?? '').isNotEmpty) ...[
              SizedBox(height: 2),
              Row(children: [
                Icon(Icons.phone_outlined, size: 13, color: p.textSecondary),
                SizedBox(width: 6),
                Text(guest.phone!,
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _infoSection(BuildContext context, GiPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GiRadius.card),
        border: Border.all(color: p.border),
      ),
      child: Column(children: [
        _DetailLine(
            icon: Icons.people_outline,
            label: 'Personnes max',
            value: '${(guest.allowedCompanions ?? 0) + 1}'),
        _DetailLine(
            icon: Icons.info_outline,
            label: 'Statut RSVP',
            widget: RsvpStatusBadge(status: rsvp?.status)),
        _DetailLine(
            icon: Icons.check_circle_outline,
            label: 'Personnes',
            value: '${rsvp?.numberOfAttendees ?? 0}'),
        _DetailLine(
            icon: Icons.notes_outlined,
            label: 'Notes',
            value: (guest.notes ?? '').isNotEmpty ? guest.notes! : 'Aucune note'),
      ]),
    );
  }
}