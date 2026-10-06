import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import 'checkin_api.dart';
import 'checkin_offline_manager.dart';
import 'checkin_offline_models.dart';
import 'checkin_providers.dart';

/// Écran d'accueil (agent) : saisit un QR/token, consulte l'état, enregistre
/// l'entrée dans la limite du RSVP. Permission `CHECKIN_CREATE`.
/// Supporte le mode hors ligne via le pack préchargé.
class CheckInScanPage extends ConsumerStatefulWidget {
  const CheckInScanPage({super.key, required this.weddingId});

  final int weddingId;

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
  int _attendees = 1;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    // Synchronisation automatique lorsque le réseau revient.
    ref.listen<bool>(
      offlineCheckInManagerProvider,
      (previous, next) {
        if (next && previous == false) {
          _syncOfflineScans();
        }
      },
    );
  }

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
      CheckInScan result;
      if (_offline) {
        final manager = ref.read(offlineCheckInManagerProvider.notifier);
        final local = await manager.lookupLocally(token, widget.weddingId);
        if (local == null) {
          throw Exception('Invitation introuvable hors ligne');
        }
        result = local;
      } else {
        result = await api.scan(
          weddingId: widget.weddingId,
          qrToken: token,
        );
      }
      if (!mounted) return;
      setState(() {
        _scan = result;
        _attendees = 1;
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
    if (scan == null || !scan.canCheckIn || scan.remainingAttendees <= 0) {
      return;
    }
    setState(() => _recording = true);
    try {
      final api = ref.read(checkInApiProvider);
      final manager = ref.read(offlineCheckInManagerProvider.notifier);

      if (_offline) {
        await manager.queueScan(
          QueuedOfflineScan(
            qrToken: _tokenController.text.trim(),
            numberOfAttendees: _attendees,
            scannedAt: DateTime.now().toIso8601String(),
            deviceId: 'flutter-app',
            sequence: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          widget.weddingId,
        );
        if (!mounted) return;
        setState(() {
          _recordResult = 'Entrée enregistrée hors ligne (à synchroniser)';
          _recording = false;
        });
        return;
      }

      final result = await api.checkIn(
        weddingId: widget.weddingId,
        qrToken: _tokenController.text.trim(),
        numberOfAttendees: _attendees,
      );
      if (!mounted) return;
      setState(() {
        _recordResult =
            'Entrée enregistrée — ${result.tableName != null && result.tableName!.trim().isNotEmpty ? 'table : ${result.tableName} · ' : ''}restants : ${result.remainingAttendees ?? '?'}';
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

  Future<void> _syncOfflineScans() async {
    final manager = ref.read(offlineCheckInManagerProvider.notifier);
    final result = await manager.syncQueuedScans(widget.weddingId);
    if (!mounted) return;
    setState(() {
      _recordResult = result.synced
          ? 'Synchronisation : ${result.accepted} accepté(s), ${result.rejected} rejeté(s)'
          : 'Synchronisation impossible (hors ligne)';
    });
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
            Row(
              children: [
                Switch(
                  value: _offline,
                  onChanged: (v) => setState(() => _offline = v),
                ),
                const SizedBox(width: 8),
                Text(_offline ? 'Hors ligne' : 'En ligne'),
                const Spacer(),
                Consumer(
                  builder: (context, ref, _) {
                    final online = ref.watch(offlineCheckInManagerProvider);
                    return Chip(
                      label: Text(online ? 'Connecté' : 'Hors ligne'),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ],
            ),
            if (_offline) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _scanning
                    ? null
                    : () async {
                        final ok = await ref
                            .read(offlineCheckInManagerProvider.notifier)
                            .downloadOfflinePack(widget.weddingId);
                        if (!mounted) return;
                        setState(() {
                          _recordResult = ok
                              ? 'Pack hors ligne mis à jour'
                              : 'Échec du téléchargement du pack';
                        });
                      },
                child: const Text('Télécharger le pack hors ligne'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _recording
                    ? null
                    : () async {
                        await _syncOfflineScans();
                      },
                child: const Text('Synchroniser les scans'),
              ),
            ],
            const SizedBox(height: 16),
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
              child: Text(_offline ? 'Rechercher hors ligne' : 'Scanner / Vérifier'),
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
        if (scan.tableName != null && scan.tableName!.trim().isNotEmpty)
          Text(
            'Table : ${scan.tableName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        Text('RSVP : ${scan.rsvpStatus ?? '—'}'),
        Text(
          'Attendus : ${scan.expectedAttendees} · Entrés : ${scan.checkedInAttendees}'
          ' · Restants : ${scan.remainingAttendees}',
        ),
        const SizedBox(height: 12),
        if (scan.canCheckIn && scan.remainingAttendees > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _attendees > 1
                    ? () => setState(() => _attendees--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_attendees',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: _attendees < scan.remainingAttendees
                    ? () => setState(() => _attendees++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _recording ? null : _recordEntry,
            child: Text(
              _attendees > 1
                  ? 'Enregistrer $_attendees entrées'
                  : "Enregistrer l'entrée",
            ),
          ),
        ] else
          Text(
            'Impossible d’enregistrer (RSVP absent, annulé ou complet)',
            style: TextStyle(color: Colors.orange),
          ),
      ],
    );
  }
}
