import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'invitation_api.dart';
import 'invitation_providers.dart';

/// Affichage du QR code d'une invitation (data URI PNG renvoyé par le backend).
class InvitationQrPage extends ConsumerStatefulWidget {
  const InvitationQrPage({super.key, required this.weddingId, required this.invitation});

  final int weddingId;
  final Invitation invitation;

  @override
  ConsumerState<InvitationQrPage> createState() => _InvitationQrPageState();
}

class _InvitationQrPageState extends ConsumerState<InvitationQrPage> {
  bool _loading = true;
  String? _error;
  String? _dataUri;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(invitationApiProvider);
      final qr = await api.getQr(widget.weddingId, widget.invitation.id);
      if (!mounted) return;
      setState(() {
        _dataUri = qr.dataUri;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le QR';
        _loading = false;
      });
    }
  }

  /// Décode la partie base64 d'un data URI PNG (`data:image/png;base64,...`).
  Uint8List? _pngBytes(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma < 0) return null;
    final b64 = dataUri.substring(comma + 1);
    if (b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    return Scaffold(
      appBar: AppBar(title: Text('QR — ${inv.invitationCode}')),
      body: _buildBody(inv),
    );
  }

  Widget _buildBody(Invitation inv) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final uri = _dataUri;
    if (uri == null || uri.isEmpty) {
      return Center(child: const Text('QR indisponible'));
    }
    final png = _pngBytes(uri);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (png != null)
            Image.memory(
              png,
              width: 220,
              height: 220,
            )
          else
            const Text('Impossible de lire le QR'),
          const SizedBox(height: 16),
          Text(inv.invitationCode),
        ],
      ),
    );
  }
}