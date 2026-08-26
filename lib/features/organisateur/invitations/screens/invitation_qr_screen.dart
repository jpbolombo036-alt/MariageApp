import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';
import '../widgets/backend_qr_image.dart';
import '../widgets/invitation_status_badge.dart';

/// Écran QR Code complet d'une invitation.
class InvitationQrScreen extends StatelessWidget {
  const InvitationQrScreen({
    super.key,
    required this.guestName,
    required this.status,
    required this.code,
    this.qrDataUri,
    this.rsvpSummary,
  });

  final String guestName;
  final String? status;
  final String code;
  final String? qrDataUri;

  /// Texte RSVP réel fourni par l'appelant (issu du backend) ; sinon neutre.
  final String? rsvpSummary;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, size: 22, color: p.textPrimary),
        ),
        title: Text('QR Code de l\u2019invitation',
            style: InvType.appBarTitle(p.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InvSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Montrez ce code à l\u2019entrée de l\u2019événement',
                textAlign: TextAlign.center,
                style: InvType.subtitle(p.textSecondary),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(InvRadius.card),
                    border: Border.all(color: InvColors.primary, width: 1.2),
                    boxShadow: p.cardShadow,
                  ),
                  child: BackendQrImage(dataUri: qrDataUri, size: 210),
                ),
              ),
              const SizedBox(height: 20),
              _row(context, Icons.person_outline, guestName,
                  trailing: InvitationStatusBadge(status: status)),
              const SizedBox(height: 10),
              _row(context, Icons.tag_outlined, code.isEmpty ? '—' : code),
              const SizedBox(height: 10),
              _row(context, Icons.people_outline,
                  rsvpSummary ?? 'Réponse en attente'),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _action(context, Icons.ios_share_outlined, 'Partager', () {}),
                  _action(context, Icons.download_outlined, 'Télécharger', () {}),
                  _action(context, Icons.copy_outlined, 'Copier', () {}),
                  _action(context, Icons.print_outlined, 'Imprimer', () {}),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Les actions dépendent des services disponibles sur la plateforme.',
                textAlign: TextAlign.center,
                style: InvType.cardMuted(p.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text,
      {Widget? trailing}) {
    final p = InvPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.field),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: InvColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: InvType.cardBody(p.textPrimary)),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final p = InvPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: InvColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: InvColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: InvType.badge(p.textSecondary)),
          ],
        ),
      ),
    );
  }
}