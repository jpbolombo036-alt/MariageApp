import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/theme/app_colors.dart';

/// Écran de résultat d'un scan QR (succès / enregistrement d'entrée).
class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({super.key, required this.scan, required this.qrToken});

  final CheckInScan scan;
  final String qrToken;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  int _attendees = 1;
  bool _recording = false;
  CheckInResult? _result;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Résultat'),
      ),
      body: _result != null ? _buildSuccess() : _buildScanInfo(),
    );
  }
Widget _buildScanInfo() {
    final s = widget.scan;
    final success = s.canCheckIn && s.remainingAttendees > 0;
    final max = s.remainingAttendees > 0 ? s.remainingAttendees : 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: success ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                success ? 'INVITÉ TROUVÉ' : 'PROBLÈME',
                style: const TextStyle(
                  color: AppColors.agentNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.guestName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.agentNavy, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (success)
                _infoRow('Invitation : Confirmée')
              else
                _infoRow('Invitation : ${_statusLabel(s)}'),
              _infoRow('Personnes attendues : ${s.expectedAttendees}'),
              _infoRow('Déjà enregistrées : ${s.checkedInAttendees}'),
              _infoRow('Restantes : ${s.remainingAttendees}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        if (success) ...[
          Text(
            'Nombre de personnes à enregistrer',
            style: const TextStyle(color: AppColors.agentTextSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _attendees > 1 ? () => setState(() => _attendees--) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 34),
              ),
              Container(
                width: 64,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Text(
                  '$_attendees',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.agentNavy),
                ),
              ),
              IconButton(
                onPressed: _attendees < max ? () => setState(() => _attendees++) : null,
                icon: const Icon(Icons.add_circle_outline, size: 34),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _recording ? null : _record,
            icon: _recording
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.person_add_alt),
            label: Text(_recording ? 'Enregistrement...' : '+ Enregistrer l\u2019entrée'),
          ),
        ] else ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ],
    );
  }
Widget _buildSuccess() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 12),
              const Text(
                'ENTRÉE ENREGISTRÉE',
                style: TextStyle(color: AppColors.agentNavy, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                r.guestName ?? '',
                style: const TextStyle(color: AppColors.agentNavy, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _infoRow('Enregistrées / attendues : ${r.checkedInAttendees} / ${r.expectedAttendees}'),
              _infoRow('Restantes : ${r.remainingAttendees}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      final result = await ref.read(checkInApiProvider).checkIn(
            qrToken: widget.qrToken,
            numberOfAttendees: _attendees,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _recording = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _error = 'Enregistrement refusé (capacité ou état invalide)';
      });
    }
  }

  String _statusLabel(CheckInScan s) {
    if (s.remainingAttendees <= 0) return 'Capacité atteinte';
    final st = (s.rsvpStatus ?? '').toUpperCase();
    if (st == 'DECLINED') return 'Non confirmée';
    return 'En attente';
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.agentNavy, fontSize: 16),
      ),
    );
  }
}