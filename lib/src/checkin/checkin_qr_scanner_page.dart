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
      ),
    );
  }
}
