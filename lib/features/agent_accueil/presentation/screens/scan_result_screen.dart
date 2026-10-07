import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_offline_manager.dart';
import '../../../../src/checkin/checkin_offline_models.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/theme/app_colors.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.scan,
    required this.qrToken,
    required this.weddingId,
    this.offline = false,
  });

  final CheckInScan scan;
  final String qrToken;
  final int weddingId;
  final bool offline;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  int _attendees = 1;
  bool _recording = false;
  CheckInResult? _result;
  String? _error;
  CheckInScan? _localScan;

  CheckInScan get _scan {
    return _localScan ?? widget.scan;
  }

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        title: const Text('Résultat'),
      ),
      body: _result != null ? _buildSuccess(p) : _buildScanInfo(p),
    );
  }

  Widget _buildScanInfo(AgentPalette p) {
    final s = _scan;
    final success = s.canCheckIn && s.remainingAttendees > 0;
    final max = s.remainingAttendees > 0 ? s.remainingAttendees : 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: success ? AppColors.success : p.danger,
              ),
              const SizedBox(height: 12),
              Text(
                success ? 'INVITÉ TROUVÉ' : 'PROBLÈME',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.guestName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(
                'Invitation : ${success ? "Confirmée" : _statusLabel(s)}',
                p,
              ),
              if (s.tableName != null && s.tableName!.trim().isNotEmpty)
                _infoRow('Table : ${s.tableName}', p),
              _infoRow('Personnes attendues : ${s.expectedAttendees}', p),
              _infoRow('Déjà enregistrées : ${s.checkedInAttendees}', p),
              _infoRow('Restantes : ${s.remainingAttendees}', p),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        if (success) ...[
          Text(
            'Nombre de personnes à enregistrer',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _attendees > 1
                    ? () => setState(() => _attendees--)
                    : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 34,
                  color: p.textSecondary,
                ),
              ),
              Container(
                width: 64,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  '$_attendees',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: p.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _attendees < max
                    ? () => setState(() => _attendees++)
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 34,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _recording ? null : _record,
            icon: _recording
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.person_add_alt),
            label: Text(
              _recording ? 'Enregistrement...' : '+ Enregistrer l\u2019entrée',
            ),
          ),
        ] else ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.danger,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess(AgentPalette p) {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 12),
              Text(
                'ENTRÉE ENREGISTRÉE',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                r.guestName ?? '',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(
                'Enregistrées / attendues : ${r.checkedInAttendees} / ${r.expectedAttendees}',
                p,
              ),
              if (r.tableName != null && r.tableName!.trim().isNotEmpty)
                _infoRow('Table : ${r.tableName}', p),
              _infoRow('Restantes : ${r.remainingAttendees}', p),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Terminer'),
        ),
      ],
    );
  }

  Future<void> _record() async {
    setState(() {
      _recording = true;
      _error = null;
    });
    try {
      if (widget.offline) {
        final manager = ref.read(offlineCheckInManagerProvider.notifier);
        await manager.queueScan(
          QueuedOfflineScan(
            qrToken: widget.qrToken,
            numberOfAttendees: _attendees,
            scannedAt: DateTime.now().toIso8601String(),
            deviceId: 'flutter-app',
            sequence: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          widget.weddingId,
        );
        if (!mounted) return;
        setState(() {
          _recording = false;
          _localScan = CheckInScan(
            guestName: widget.scan.guestName,
            weddingDisplayName: widget.scan.weddingDisplayName,
            invitationStatus: widget.scan.invitationStatus,
            rsvpStatus: widget.scan.rsvpStatus,
            expectedAttendees: widget.scan.expectedAttendees,
            checkedInAttendees: widget.scan.checkedInAttendees + _attendees,
            remainingAttendees: widget.scan.remainingAttendees - _attendees,
            canCheckIn: widget.scan.remainingAttendees - _attendees > 0 &&
                widget.scan.canCheckIn,
            tableName: widget.scan.tableName,
            drinkChoice: widget.scan.drinkChoice,
            publicToken: widget.scan.publicToken,
            invitationCode: widget.scan.invitationCode,
            hasCard: widget.scan.hasCard,
            checkedInAt: widget.scan.checkedInAt,
            eventName: widget.scan.eventName,
            eventDate: widget.scan.eventDate,
            eventTime: widget.scan.eventTime,
            eventVenue: widget.scan.eventVenue,
          );
          _result = CheckInResult(
            guestName: widget.scan.guestName,
            checkedInAttendees: widget.scan.checkedInAttendees + _attendees,
            remainingAttendees: widget.scan.remainingAttendees - _attendees,
            tableName: widget.scan.tableName,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrée enregistrée hors ligne (à synchroniser)'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }
      final result = await ref
          .read(checkInApiProvider)
          .checkIn(
            weddingId: widget.weddingId,
            qrToken: widget.qrToken,
            numberOfAttendees: _attendees,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _recording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entrée enregistrée pour ${result.guestName ?? 'invité'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _error = 'Enregistrement refusé (capacité ou état invalide)';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _statusLabel(CheckInScan s) {
    if (s.remainingAttendees <= 0) return 'Capacité atteinte';
    final st = (s.rsvpStatus ?? '').toUpperCase();
    if (st == 'DECLINED') return 'Non confirmée';
    return 'En attente';
  }

  Widget _infoRow(String text, AgentPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: p.textSecondary, fontSize: 16),
      ),
    );
  }
}
