import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/checkin/checkin_qr_scanner_page.dart';
import '../../../../src/theme/app_colors.dart';
import 'scan_result_screen.dart';

/// Écran de scan QR de l'espace AGENT_ACCUEIL.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _analyzing = false;
  bool _openingScanner = false;
  String? _error;

  Future<void> _startScan(WidgetRef ref) async {
    // Synchronous guard: prevents two concurrent scans/route pushes (which
    // corrupt the Navigator transitions and cause "RenderBox was not laid
    // out" assertions).
    if (_openingScanner) return;
    _openingScanner = true;
    setState(() => _error = null);

    try {
      final token = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const CheckInQrScannerPage()),
      );
      if (token == null || token.isEmpty || !mounted) return;

      setState(() {
        _analyzing = true;
        _error = null;
      });

      try {
        final scan = await ref.read(checkInApiProvider).scan(token);
        if (!mounted) return;
        // Stop the analyzing spinner *before* covering this screen with an
        // opaque route. A repeating CircularProgressIndicator that keeps
        // scheduling paint frames on a covered route during the transition is a
        // known trigger for the "RenderBox was not laid out" assertion. The
        // _openingScanner guard still blocks any re-entry while we're gone.
        setState(() {
          _analyzing = false;
          _error = null;
        });
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              scan: scan,
              qrToken: token,
            ),
          ),
        );
        if (!mounted) return;
        if (result == true) {
          setState(() => _analyzing = false);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _analyzing = false;
          _error = _translateError(e);
        });
      }
    } finally {
      _openingScanner = false;
    }
  }

  String _translateError(Object e) {
    final msg = e.toString();
    final lower = msg.toLowerCase();
    if (lower.contains('annul')) return 'Cette invitation a été annulée';
    if (lower.contains('expir')) return 'Cette invitation a expiré';
    if (lower.contains('confir')) {
      return 'Cet invité n\u2019a pas confirmé sa présence';
    }
    if (lower.contains('cap') || lower.contains('plein') || lower.contains('complet')) {
      return 'Toutes les personnes prévues ont déjà été enregistrées';
    }
    return 'QR code invalide';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Scanner l\u2019invitation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer(builder: (context, ref, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Placez le QR code dans le cadre',
                style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _analyzing
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.agentGold),
                        )
                      : Center(
                          child: FilledButton.icon(
                            onPressed: _analyzing ? null : () => _startScan(ref),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scanner'),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _analyzing ? null : () => _startScan(ref),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Saisir un code'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}