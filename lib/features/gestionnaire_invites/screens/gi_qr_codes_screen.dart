import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/guest/guest_api.dart';
import '../../../src/guest/guest_providers.dart';
import '../../../src/invitation/invitation_api.dart';
import '../../../src/invitation/invitation_providers.dart';
import '../../../src/theme/gi_ui.dart';
import '../../../src/wedding/wedding_providers.dart';
import '../../organisateur/invitations/widgets/backend_qr_image.dart';
import '../../organisateur/invitations/widgets/invitation_status_badge.dart';

/// Écran « QR Codes » du rôle GESTIONNAIRE_INVITES.
class GiQrCodesScreen extends ConsumerStatefulWidget {
  const GiQrCodesScreen({super.key});

  @override
  ConsumerState<GiQrCodesScreen> createState() => _GiQrCodesScreenState();
}

class _GiQrCodesScreenState extends ConsumerState<GiQrCodesScreen> {
  bool _loading = true;
  String? _error;
  List<Invitation> _invitations = const [];
  Map<int, Guest> _guests = const {};
  Map<int, String> _qrCache = const {};

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
        ref.read(invitationApiProvider).list(w.id, size: 200),
        ref.read(guestApiProvider).listGuests(w.id, size: 200),
      ]);
      if (!mounted) return;
      final invs = results[0] as List<Invitation>;
      final guests = results[1] as List<Guest>;
      setState(() {
        _invitations = invs;
        _guests = {for (final g in guests) g.id: g};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur'; });
    }
  }

  Future<String?> _qrFor(Invitation inv) async {
    final cached = _qrCache[inv.id];
    if (cached != null) return cached;
    try {
      final qr = await ref
          .read(invitationApiProvider)
          .getQr(inv.weddingId, inv.id);
      if (!mounted) return null;
      setState(() => _qrCache = {..._qrCache, inv.id: qr.dataUri});
      return qr.dataUri;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _qrQ(Invitation inv) => _qrFor(inv);

  String _guestName(int guestId) {
    final g = _guests[guestId];
    if (g == null) return 'Invité';
    return '${g.firstName} ${g.lastName}'.trim();
  }

  void _openDetail(Invitation inv) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            _QrDetail(inv: inv, title: _guestName(inv.guestId))));
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
        title: Text('QR Codes', style: TextStyle(color: p.textPrimary)),
      ),
      body: SafeArea(child: _body(context, p)),
    );
  }

  Widget _body(BuildContext context, GiPalette p) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(strokeWidth: 2.6, color: p.primary));
    }
    if (_error != null) {
      return Center(
          child: Text('Impossible de charger les QR Codes',
              style: TextStyle(fontSize: 13, color: p.textSecondary)));
    }
    if (_invitations.isEmpty) {
      return Center(
          child: Text('Aucun QR Code disponible',
              style: TextStyle(fontSize: 14, color: p.textSecondary)));
    }
    return RefreshIndicator(
      color: p.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _invitations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final inv = _invitations[i];
          return FutureBuilder<String?>(
            future: _qrQ(inv),
            builder: (context, snap) {
              final uri = snap.data;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openDetail(inv),
                  borderRadius: BorderRadius.circular(GiRadius.card),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(GiRadius.card),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 56, height: 56,
                        child: BackendQrImage(dataUri: uri, size: 56),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_guestName(inv.guestId),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: p.textPrimary)),
                          if (inv.invitationCode.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(inv.invitationCode,
                                style: TextStyle(
                                    fontSize: 11, color: p.textSecondary)),
                          ],
                        ])),
                      InvitationStatusBadge(status: inv.status),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Détail d'un QR code (version agrandie, réutilise le renderer backend).
class _QrDetail extends ConsumerStatefulWidget {
  const _QrDetail({required this.inv, required this.title});

  final Invitation inv;
  final String title;

  @override
  ConsumerState<_QrDetail> createState() => _QrDetailState();
}

class _QrDetailState extends ConsumerState<_QrDetail> {
  String? _uri;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadQr);
  }

  Future<void> _loadQr() async {
    try {
      final qr = await ref
          .read(invitationApiProvider)
          .getQr(widget.inv.weddingId, widget.inv.id);
      if (mounted) setState(() => _uri = qr.dataUri);
    } catch (_) {
      // QR indisponible → affichage neutre.
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
        title: Text('QR Code', style: TextStyle(color: p.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.inv.invitationCode,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.textSecondary)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(GiRadius.card),
                border: Border.all(color: p.primary, width: 1.2),
              ),
              child: BackendQrImage(dataUri: _uri, size: 210),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: InvitationStatusBadge(status: widget.inv.status)),
        ]),
      ),
    );
  }
}