import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/guest/guest_api.dart';
import '../../../src/guest/guest_providers.dart';
import '../../../src/rsvp/rsvp_api.dart';
import '../../../src/theme/gi_ui.dart';
import '../../../src/wedding/wedding_api.dart';
import '../../../src/wedding/wedding_providers.dart';
import '../widgets/gi_nav.dart';
import '../widgets/guest_tiles.dart';
import 'gi_guest_detail_screen.dart';

class GiGuestsView extends ConsumerStatefulWidget {
  const GiGuestsView({super.key, this.onAddGuest});

  final VoidCallback? onAddGuest;

  @override
  ConsumerState<GiGuestsView> createState() => _GiGuestsViewState();
}

class _GiGuestsViewState extends ConsumerState<GiGuestsView> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  Wedding? _wedding;
  List<Guest> _guests = [];
  Map<int, GuestRsvp> _rsvps = {};
  String _query = '';
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
          _loading = false;
          _wedding = null;
          _guests = const [];
        });
        return;
      }
      final wedding = weddings.first;
      final results = await Future.wait([
        ref.read(guestApiProvider).listGuests(wedding.id, size: 200),
        ref.read(rsvpApiProvider).listForWedding(wedding.id),
      ]);
      if (!mounted) return;
      final guests = results[0] as List<Guest>;
      final rsvps = results[1] as List<GuestRsvp>;
      setState(() {
        _wedding = wedding;
        _guests = guests;
        _rsvps = {for (final r in rsvps) r.guestId: r};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur';
      });
    }
  }

  List<Guest> get _visible {
    final q = _query.trim().toLowerCase();
    final selected = _filter.split(' ').first.toLowerCase();
    return _guests.where((g) {
      final name = '${g.firstName} ${g.lastName}'.toLowerCase();
      if (q.isNotEmpty && !name.contains(q)) return false;
      final r = _rsvps[g.id];
      final s = (r?.status ?? '').toUpperCase();
      return switch (selected) {
        'confirmés' => s == 'ACCEPTED',
        'refusés' => s == 'DECLINED',
        'en' => s != 'ACCEPTED' && s != 'DECLINED',
        _ => true,
      };
    }).toList();
  }

  void _openDetail(Guest g, GuestRsvp? rsvp) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GiGuestDetailScreen(guest: g, rsvp: rsvp),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    final filters = [
      'Tous (${_guests.length})',
      'Confirmés (${_rsvps.values.where((r) => r.status.toUpperCase() == 'ACCEPTED').length})',
      'En attente (${_rsvps.values.where((r) => r.status.toUpperCase() != 'ACCEPTED' && r.status.toUpperCase() != 'DECLINED').length})',
      'Refusés (${_rsvps.values.where((r) => r.status.toUpperCase() == 'DECLINED').length})',
    ];
    return RefreshIndicator(
      color: p.primary,
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 13, color: p.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher un invité...',
                hintStyle: TextStyle(fontSize: 12, color: p.textSecondary),
                prefixIcon: Icon(Icons.search, size: 20, color: p.textSecondary),
                filled: true,
                fillColor: p.fieldFill,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GiRadius.field),
                  borderSide: BorderSide(color: p.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GiRadius.field),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GiRadius.field),
                  borderSide: BorderSide(color: p.primary, width: 1.2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _chip(p, filters[i]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(context, p)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: GiPrimaryButton(
                label: 'Ajouter un invité',
                icon: Icons.person_add_alt_1,
                onTap: widget.onAddGuest),
          ),
        ],
      ),
    );
  }

  Widget _chip(GiPalette p, String label) {
    final active = label == _filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? p.primary : p.surfaceAlt,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? p.primary : p.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : p.textSecondary)),
      ),
    );
  }

  Widget _body(BuildContext context, GiPalette p) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(strokeWidth: 2.6, color: p.primary));
    }
    if (_error != null) {
      return Center(
          child: Text('Impossible de charger les invités',
              style: TextStyle(fontSize: 13, color: p.textSecondary)));
    }
    if (_wedding == null || _guests.isEmpty) {
      return Center(
          child: Text('Aucun invité pour le moment',
              style: TextStyle(fontSize: 14, color: p.textSecondary)));
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return Center(
          child: Text('Aucun résultat',
              style: TextStyle(fontSize: 13, color: p.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = visible[i];
        final r = _rsvps[g.id];
        return GuestListItem(
          name: '${g.firstName} ${g.lastName}',
          subtitle: '${(g.allowedCompanions ?? 0) + 1} personnes max',
          rsvpStatus: r?.status,
          onTap: () => _openDetail(g, r),
        );
      },
    );
  }
}
