import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'checkin_api.dart';
import 'checkin_providers.dart';

/// Écran d'accueil (agent) : saisit un QR/token, consulte l'état, enregistre
/// l'entrée dans la limite du RSVP. Permission `CHECKIN_CREATE`.
class CheckInScanPage extends ConsumerStatefulWidget {
  const CheckInScanPage({super.key});

  @override
  ConsumerState<CheckInScanPage> createState() => _CheckInScanPageState();
}

class _CheckInScanPageState extends ConsumerState<CheckInScanPage> {
  final _tokenController = TextEditingController();

  bool _scanning = false;
  bool _scanDone = false;
  CheckInScan? _scan;
  bool _recording = false;
  String? _recordResult;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _doScan() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _scanning = true;
      _scanDone = false;
      _recordResult = null;
    });
    try {
      final api = ref.read(checkInApiProvider);
      final result = await api.scan(token);
      if (!mounted) return;
      setState(() {
        _scan = result;
        _scanDone = true;
        _scanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recordResult = 'QR invalide ou non autorisé';
        _scanning = false;
      });
    }
  }

  Future<void> _recordEntry() async {
    final scan = _scan;
    if (scan == null || !scan.canCheckIn || scan.remainingAttendees <= 0) return;
    setState(() => _recording = true);
    try {
      final api = ref.read(checkInApiProvider);
      final result = await api.checkIn(
        qrToken: _tokenController.text.trim(),
        numberOfAttendees: 1,
      );
      if (!mounted) return;
      setState(() {
        _recordResult =
            'Entrée enregistrée — restants : ${result.remainingAttendees ?? '?'}';
        _recording = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recordResult = 'Enregistrement refusé (dépassement?)';
        _recording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canScan = auth.hasPermission(PermissionCodes.checkinCreate);
    if (!canScan) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accueil')),
        body: Center(child: const Text('Accès non autorisé')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil — Enregistrement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Code QR (public token)',
                hintText: 'Collez le token de l’invité',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _scanning ? null : _doScan,
              child: const Text('Scanner / Vérifier'),
            ),
            const SizedBox(height: 20),
            _buildScanResult(),
            if (_recordResult != null) ...[
              const SizedBox(height: 16),
              Text(_recordResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanResult() {
    final scan = _scan;
    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_scanDone || scan == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invité : ${scan.guestName}'),
        Text('Événement : ${scan.weddingDisplayName}'),
        Text('RSVP : ${scan.rsvpStatus ?? '—'}'),
        Text(
          'Attendus : ${scan.expectedAttendees} · Entrés : ${scan.checkedInAttendees}'
          ' · Restants : ${scan.remainingAttendees}',
        ),
        const SizedBox(height: 12),
        if (scan.canCheckIn && scan.remainingAttendees > 0)
          FilledButton(
            onPressed: _recording ? null : _recordEntry,
            child: const Text("Enregistrer l'entrée"),
          )
        else
          Text(
            'Impossible d’enregistrer (RSVP absent, annulé ou complet)',
            style: TextStyle(color: Colors.orange),
          ),
      ],
    );
  }
}