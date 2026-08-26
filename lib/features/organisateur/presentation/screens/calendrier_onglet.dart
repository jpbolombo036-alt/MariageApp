import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/wedding/wedding_providers.dart';
import '../../../../src/weddingevent/wedding_event_api.dart';
import '../../../../src/weddingevent/wedding_event_providers.dart';
import '../../../../src/theme/app_theme.dart';

/// Onglet « Calendrier » : les événements du premier mariage, groupés par date.
class CalendrierOnglet extends ConsumerStatefulWidget {
  const CalendrierOnglet({super.key});

  @override
  ConsumerState<CalendrierOnglet> createState() => _CalendrierOngletState();
}

class _CalendrierOngletState extends ConsumerState<CalendrierOnglet> {
  bool _loading = true;
  String? _error;
  List<WeddingEvent> _events = const [];
  int? _weddingId;

  @override
  void initState() {
    super.initState();
    _load();
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
      final wid = weddings.first.id;
      final events =
          await ref.read(weddingEventApiProvider).list(wid, size: 60);
      if (!mounted) return;
      setState(() {
        _weddingId = wid;
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Calendrier',
              style: AppTypography.display(color: scheme.onSurface)),
          const SizedBox(height: 4),
          Text('Les temps forts de votre événement',
              style:
                  AppTypography.small(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (_error != null)
            Text('Impossible de charger le calendrier',
                style: TextStyle(color: scheme.onErrorContainer))
          else if (_weddingId == null || _events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Aucun événement programmé',
                    style: TextStyle(
                        fontSize: 14, color: scheme.onSurfaceVariant)),
              ),
            )
          else
            ..._buildGrouped(scheme),
        ],
      ),
    );
  }

  List<Widget> _buildGrouped(ColorScheme scheme) {
    final grouped = <String, List<WeddingEvent>>{};
    for (final e in _events) {
      final key = (e.eventDate != null && e.eventDate!.isNotEmpty)
          ? e.eventDate!
          : 'Sans date';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final keys = grouped.keys.toList()..sort();
    final out = <Widget>[];
    for (final key in keys) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(_formatGroup(key),
            style: AppTypography.sectionTitle(color: scheme.onSurface)),
      ));
      for (final e in grouped[key]!) {
        out.add(_eventTile(scheme, e));
      }
    }
    return out;
  }

  String _formatGroup(String date) {
    if (date == 'Sans date') return date;
    try {
      final d = DateTime.parse(date);
      const months = [
        '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
        'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _eventTile(ColorScheme scheme, WeddingEvent e) {
    final icon = switch (e.typeEnum) {
      WeddingEventType.civilCeremony => Icons.gavel_outlined,
      WeddingEventType.religiousCeremony => Icons.local_activity_outlined,
      WeddingEventType.reception => Icons.celebration_outlined,
      WeddingEventType.afterParty => Icons.nightlife_outlined,
      _ => Icons.event_outlined,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.name,
              style: AppTypography.cardTitle(color: scheme.onSurface)),
          if ((e.startTime ?? '').isNotEmpty)
            Text('${e.startTime}${(e.venueName ?? '').isNotEmpty ? ' • ${e.venueName}' : ''}',
                style: AppTypography.small(color: scheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}