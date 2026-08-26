import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/rsvp/rsvp_api.dart';
import '../../../../src/theme/gi_ui.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../widgets/guest_tiles.dart';

/// Écran « Réponses RSVP » du rôle GESTIONNAIRE_INVITES.
class GiRsvpScreen extends ConsumerStatefulWidget {
  const GiRsvpScreen({super.key});

  @override
  ConsumerState<GiRsvpScreen> createState() => _GiRsvpScreenState();
}

class _GiRsvpScreenState extends ConsumerState<GiRsvpScreen> {
  static const _filters = ['Toutes', 'Acceptées', 'Refusées', 'En attente'];

  String _filter = 'Toutes';
  bool _loading = true;
  List<Guest> _guests = const [];
  List<GuestRsvp> _rsvps = const [];
  String? _error;

  int _countFor(String filter) {
    switch (filter) {
      case 'Acceptées':
        return _rsvps.where((r) => r.status == 'ACCEPTED').length;
      case 'Refusées':
        return _rsvps.where((r) => r.status == 'DECLINED').length;
      case 'En attente':
        return _rsvps
            .where((r) => r.status != 'ACCEPTED' && r.status != 'DECLINED')
            .length;
      default:
        return _rsvps.length;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final weddings = await ref.read(weddingApiProvider).list(size: 1);
      if (!mounted) return;
      if (weddings.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      final w = weddings.first;
      final results = await Future.wait([
        ref.read(guestApiProvider).listGuests(w.id, size: 200),
        ref.read(rsvpApiProvider).listForWedding(w.id),
      ]);
      if (!mounted) return;
      setState(() {
        _guests = results[0] as List<Guest>;
        _rsvps = results[1] as List<GuestRsvp>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur'; });
    }
  }

  bool _match(String? status) {
    switch (_filter) {
      case 'Acceptées':
        return status == 'ACCEPTED';
      case 'Refusées':
        return status == 'DECLINED';
      case 'En attente':
        return status != 'ACCEPTED' && status != 'DECLINED';
      default:
        return true;
    }
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
        title:
            Text('Réponses RSVP', style: TextStyle(color: p.textPrimary)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.6, color: p.primary))
            : _error != null
                ? Center(
                    child: Text('Impossible de charger les réponses',
                        style: TextStyle(fontSize: 13, color: p.textSecondary)))
                : RefreshIndicator(
                    color: p.primary,
                    onRefresh: _load,
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => _chip(p, _filters[i]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._rows(),
                      ],
                    ),
                  ),
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
        child: Text('$label ${_countFor(label)}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : p.textSecondary)),
      ),
    );
  }

  List<Widget> _rows() {
    final p = GiPalette.of(context);
    final byId = {for (final g in _guests) g.id: g};
    final items = <Widget>[];
    for (final r in _rsvps) {
      final g = byId[r.guestId];
      if (!_match(r.status)) continue;
      final name = g == null
          ? 'Invité'
          : '${g.firstName} ${g.lastName}'.trim();
      final persons =
          '${r.numberOfAttendees ?? ((g?.allowedCompanions ?? 0) + 1)} personnes';
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GuestListItem(
            name: name, subtitle: persons, rsvpStatus: r.status),
      ));
    }
    if (items.isEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
            child: Text('Aucune réponse pour ce filtre',
                style: TextStyle(fontSize: 13, color: p.textSecondary))),
      ));
    }
    return items;
  }
}