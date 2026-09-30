import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';
import 'backend_qr_image.dart';
import 'invitation_status_badge.dart';

/// Ligne d'information (icône + label + valeur).
class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.valueWidget,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: InvColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Text(label, style: InvType.cardMuted(p.textSecondary)),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  textAlign: TextAlign.right,
                  style: InvType.cardBody(valueColor ?? p.textPrimary),
                ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Carte « Informations sur l'invitation ».
class InvitationDetailsInfoCard extends StatelessWidget {
  const InvitationDetailsInfoCard({
    super.key,
    required this.sentDate,
    required this.code,
    required this.status,
    this.publicLink,
    this.rsvpCount,
    this.updatedDate,
    this.onCopyLink,
  });

  final String sentDate;
  final String code;
  final String? status;
  final String? publicLink;
  final String? rsvpCount;
  final String? updatedDate;
  final VoidCallback? onCopyLink;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InvSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.card),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations sur l\u2019invitation',
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.send_outlined,
            label: 'Date d\u2019envoi',
            value: sentDate,
          ),
          _InfoLine(
            icon: Icons.tag_outlined,
            label: 'Code',
            value: code,
          ),
          _InfoLine(
            icon: Icons.link_outlined,
            label: 'Lien public',
            value: (publicLink != null && publicLink!.isNotEmpty)
                ? publicLink!
                : '—',
            trailing: onCopyLink != null
                ? _IconAction(
                    onTap: onCopyLink!,
                    icon: Icons.copy_outlined,
                  )
                : null,
          ),
          _InfoLine(
            icon: Icons.info_outline,
            label: 'Statut',
            valueWidget: Align(
              alignment: Alignment.centerRight,
              child: InvitationStatusBadge(status: status),
            ),
          ),
          if (rsvpCount != null) ...[
            _InfoLine(
              icon: Icons.people_outline,
              label: 'Réponse RSVP',
              value: rsvpCount,
              valueColor: InvColors.success,
            ),
          ],
          if (updatedDate != null)
            _InfoLine(
              icon: Icons.update_outlined,
              label: 'Mise à jour',
              value: updatedDate,
            ),
        ],
      ),
    );
  }
}

/// Carte « QR Code » (avec le QR réel du backend, sinon message honnête).
class InvitationQrCard extends StatelessWidget {
  const InvitationQrCard({super.key, required this.qrDataUri});

  final String? qrDataUri;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InvSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.card),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QR Code',
              style: InvType.cardBody(p.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          BackendQrImage(dataUri: qrDataUri, size: 170),
          const SizedBox(height: 12),
          Text(
            'Scannez ce QR code pour l\u2019accès à l\u2019événement',
            textAlign: TextAlign.center,
            style: InvType.subtitle(p.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action pleine largeur (normal ou destructif).
class InvitationActionButton extends StatelessWidget {
  const InvitationActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.destructive = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? InvColors.destructive : InvColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: destructive
            ? InvColors.destructive.withValues(alpha: 0.08)
            : InvColors.primaryLight,
        borderRadius: BorderRadius.circular(InvRadius.field),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(InvRadius.field),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Text(label, style: InvType.button(fg)),
            ],
          ),
        ),
      ),
    );
  }
}
              class _IconAction extends StatelessWidget {
  const _IconAction({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18, color: InvColors.primary),
    );
  }
}