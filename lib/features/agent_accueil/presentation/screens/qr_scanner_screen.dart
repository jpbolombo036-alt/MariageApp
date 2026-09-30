import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/theme/app_colors.dart';
import 'scan_result_screen.dart';

const Color _agentBackground = Colors.white;

/// Écran de scan de l'espace agent. La caméra reste dans le cadre :
/// le retour et la saisie manuelle restent toujours utilisables.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _camera;
  bool _lookingUp = false;
  bool _cameraOn = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _camera?.dispose();
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleCamera() async {
    if (_lookingUp) return;
    if (_cameraOn) {
      final camera = _camera;
      _camera = null;
      setState(() => _cameraOn = false);
      await camera?.dispose();
      return;
    }
    setState(() {
      _error = null;
      _cameraOn = true;
      _camera = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
    });
  }

  Future<void> _lookup(String raw) async {
    final token = invitationTokenFromInput(raw);
    if (_lookingUp || token.isEmpty) return;
    _lookingUp = true;
    setState(() => _error = null);
    try {
      final scan = await ref.read(checkInApiProvider).scan(
            weddingId: widget.weddingId,
            qrToken: token,
          );
      if (!mounted) return;
      setState(() => _lookingUp = false);
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              scan: scan,
              qrToken: token,
              weddingId: widget.weddingId,
            ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _error = _translateError(e);
      });
    }
  }

  String _translateError(Object e) {
    final lower = e.toString().toLowerCase();
    if (lower.contains('annul')) return 'Cette invitation a été annulée';
    if (lower.contains('expir')) return 'Cette invitation a expiré';
    if (lower.contains('confir')) {
      return 'Cet invité n’a pas confirmé sa présence';
    }
    if (lower.contains('cap') || lower.contains('plein') || lower.contains('complet')) {
      return 'Toutes les personnes prévues ont déjà été enregistrées';
    }
    return 'QR code invalide';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _agentBackground,
      appBar: AppBar(
        backgroundColor: _agentBackground,
        foregroundColor: AppColors.agentNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: _close,
        ),
        title: const Text('Scanner l’invitation'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Placez le QR code dans le cadre, ou saisissez le code.',
            style: TextStyle(color: AppColors.agentTextSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: AppColors.agentNavy,
                child: _cameraOn && _camera != null
                    ? MobileScanner(
                        controller: _camera,
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            final raw = barcode.rawValue;
                            if (raw == null || raw.trim().isEmpty) continue;
                            _lookup(raw);
                            return;
                          }
                        },
                        placeholderBuilder: (_) => const _CameraMessage(
                          icon: Icons.qr_code_scanner,
                          message: 'Ouverture de la caméra…',
                        ),
                        errorBuilder: (context, error) => _CameraMessage(
                          icon: Icons.no_photography_outlined,
                          message: error.errorDetails?.message ??
                              'Caméra indisponible. Saisissez le code ci-dessous.',
                        ),
                      )
                    : const _CameraMessage(
                        icon: Icons.qr_code_scanner,
                        message: 'Appuyez sur Scanner pour ouvrir la caméra',
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lookingUp)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.agentGold),
              ),
            ),
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
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _codeController,
            style: const TextStyle(color: AppColors.agentNavy),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              labelText: 'Code de l’invitation',
              labelStyle: const TextStyle(color: AppColors.agentTextSecondary),
              hintText: 'Collez le jeton du QR',
              prefixIcon: const Icon(Icons.keyboard, color: AppColors.agentNavy),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
            onSubmitted: _lookup,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.agentGold,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _lookingUp ? null : () => _toggleCamera(),
            icon: Icon(_cameraOn ? Icons.close : Icons.qr_code_scanner),
            label: Text(_cameraOn ? 'Fermer la caméra' : 'Scanner'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.agentGold,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.agentGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _lookingUp ? null : () => _lookup(_codeController.text),
            icon: const Icon(Icons.check),
            label: const Text('Vérifier le code'),
          ),
        ],
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.agentGold, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
