import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/auth/auth_providers.dart';
import '../../../src/dashboard/dashboard_providers.dart';
import '../../../src/theme/gi_ui.dart';
import '../../../src/wedding/wedding_providers.dart';
import '../widgets/gi_header_stats.dart';
import '../widgets/gi_modules.dart';

/// Onglet Accueil — tableau de bord GESTIONNAIRE_INVITES.
class GiDashboardTab extends ConsumerStatefulWidget {
  const GiDashboardTab({super.key, this.onOpenModule});

  final void Function(int index)? onOpenModule;

  @override
  ConsumerState<GiDashboardTab> createState() => _GiDashboardTabState();
}

class _GiDashboardTabState extends ConsumerState<GiDashboardTab> {
  bool _loading = true;
  String? _weddingName;
  String _status = '';
  int guests = 0, sent = 0, pending = 0, accepted = 0, present = 0, tables = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final weddings = await ref.read(weddingApiProvider).list(size: 1);
      if (!mounted) return;
      if (weddings.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final w = weddings.first;
      final dash = await ref.read(dashboardApiProvider).getForWedding(w.id);
      if (!mounted) return;
      setState(() {
        _weddingName = w.displayName;
        _status = w.status.isNotEmpty ? w.status : 'DRAFT';
        guests = dash.guests.total;
        accepted = dash.invitations.accepted;
        pending = dash.invitations.pending;
        sent = dash.invitations.total - pending;
        present = dash.attendance.checkedIn;
        tables = dash.tables.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    if (_loading) {
      return Center(
          child:
              CircularProgressIndicator(strokeWidth: 2.6, color: p.primary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GiHeader(firstName: _firstName()),
            const SizedBox(height: 16),
            _eventCard(p),
            const SizedBox(height: 24),
            Text('Aperçu rapide',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: GiQuickStatCard(icon: Icons.group_outlined, iconBg: p.primaryLightBg, value: '$guests', label: 'Invités')),
              const SizedBox(width: 10),
              Expanded(child: GiQuickStatCard(icon: Icons.mail_outline_outlined, iconBg: p.primaryLightBg, value: '$sent', label: 'Confirmés')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GiQuickStatCard(icon: Icons.access_time_rounded, iconBg: p.warningBg, value: '$present', label: 'Présents')),
              const SizedBox(width: 10),
              Expanded(child: GiQuickStatCard(icon: Icons.event_seat_outlined, iconBg: p.primaryLightBg, value: '$tables', label: 'Tables')),
            ]),
            const SizedBox(height: 24),
            GiModulesGrid(onTap: widget.onOpenModule),
          ]),
    );
  }

  String _firstName() {
    final user = ref.watch(authControllerProvider).user;
    final n = user?.firstName ?? '';
    return n.isNotEmpty ? n : 'Marie';
  }

  Widget _eventCard(GiPalette p) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GiRadius.card),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(GiRadius.miniImage),
             child: Container(
                 width: 64,
                 height: 64,
                 color: p.primaryLightBg,
                 child: Icon(Icons.auto_awesome, size: 26, color: p.primary))),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weddingName ?? 'Aucun événement',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: .4,
                          color: p.textSecondary)),
                ])),
        Icon(Icons.expand_more, size: 22, color: p.textSecondary),
      ]),
    );
  }
}