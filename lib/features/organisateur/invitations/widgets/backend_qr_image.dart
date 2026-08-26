import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// Affiche un QR Code issu réellement du backend (data URI PNG `dataUri`).
/// Si aucun `dataUri` n'est fourni, affiche un emplacement violet discret avec
/// un message — jamais un faux QR inventé.
class BackendQrImage extends StatelessWidget {
  const BackendQrImage({
    super.key,
    required this.dataUri,
    this.size = 160,
  });

  final String? dataUri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final decoded = _decode(dataUri);
    if (decoded != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(decoded, fit: BoxFit.contain),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: InvColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.qr_code_2, size: 56, color: InvColors.primary),
    );
  }

  /// Décode une data URI "data:image/png;base64,XXXX" en octets image.
  Uint8List? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final mimeAndData = raw.split(',');
    if (mimeAndData.length != 2) return null;
    try {
      return base64Decode(mimeAndData[1]);
    } catch (_) {
      return null;
    }
  }
}