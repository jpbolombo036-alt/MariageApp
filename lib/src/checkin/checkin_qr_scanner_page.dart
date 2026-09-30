import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'checkin_api.dart';

/// Caméra plein écran : lit un QR et renvoie le jeton public (pop).
class CheckInQrScannerPage extends StatefulWidget {
  const CheckInQrScannerPage({super.key});

  @override
  State<CheckInQrScannerPage> createState() => _CheckInQrScannerPageState();
}

class _CheckInQrScannerPageState extends State<CheckInQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitManual(String raw) {
    if (_handled || raw.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(invitationTokenFromInput(raw));
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(invitationTokenFromInput(raw));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR'),
        actions: [
          IconButton(
            tooltip: 'Lampe',
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) => _CameraUnavailable(
          message: error.errorDetails?.message ??
              'La caméra est indisponible sur cet appareil.',
          onSubmit: _submitManual,
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatefulWidget {
  const _CameraUnavailable({required this.message, required this.onSubmit});

  final String message;
  final ValueChanged<String> onSubmit;

  @override
  State<_CameraUnavailable> createState() => _CameraUnavailableState();
}

class _CameraUnavailableState extends State<_CameraUnavailable> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 16),
          Text(widget.message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Code de l’invitation',
              hintText: 'Collez le jeton du QR',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => widget.onSubmit(_controller.text),
            child: const Text('Vérifier le code'),
          ),
        ],
      ),
    );
  }
}
