import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/invitation/invitation_api.dart';
import '../../../../src/invitation/invitation_providers.dart';
import '../../../../src/theme/invitation_ui.dart';
import '../widgets/invitation_details_widgets.dart';
import '../widgets/invitation_status_badge.dart';
import 'invitation_qr_screen.dart';
import 'invitations_list_screen.dart';

/// Écran de détail d'une invitation.
class InvitationDetailsScreen extends ConsumerStatefulWidget {
  const InvitationDetailsScreen({super.key, required this.row});

  final InvitationRow row;

  @override
  ConsumerState<InvitationDetailsScreen> createState() =>
      _InvitationDetailsScreenState();
}

class _InvitationDetailsScreenState
    extends ConsumerState<InvitationDetailsScreen> {
  String? _qrDataUri;
  bool _busy = false;
  String? _publicLink;

  InvitationRow get row => widget.row;
  Invitation get _inv => row.invitation;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    try {
      final qr = await ref
          .read(invitationApiProvider)
          .getQr(_inv.weddingId, _inv.id);
      if (!mounted) return;
      setState(() => _qrDataUri = qr.dataUri);
    } catch (_) {
      // QR indisponible : l'écran affichera un emplacement neutre.
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(invitationApiProvider).send(_inv.weddingId, _inv.id);
      if (!mounted) return;
      // Le backend renvoie le lien public destiné à l'organisateur.
      if (res.publicInviteUrl != null && res.publicInviteUrl!.isNotEmpty) {
        setState(() => _publicLink = res.publicInviteUrl);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((res.emailSent ?? false)
              ? 'Invitation envoyée par email'
              : 'Invitation générée — partagez le lien'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Envoi impossible')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Renvoi (uniquement si déjà envoyée, selon le backend).
  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(invitationApiProvider).resend(_inv.weddingId, _inv.id);
      if (!mounted) return;
      if (res.publicInviteUrl != null && res.publicInviteUrl!.isNotEmpty) {
        setState(() => _publicLink = res.publicInviteUrl);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invitation renvoyée')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Renvoi impossible')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette invitation ?'),
        content: const Text(
            'Cette action empêchera son utilisation pour répondre ou accéder à l\u2019événement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: InvColors.destructive),
            child: const Text('Annuler l\u2019invitation'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(invitationApiProvider).cancel(_inv.weddingId, _inv.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Annulation impossible')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink() async {
    final link = _publicLink;
    if (link == null || link.isEmpty) {
      // Le lien public n'est disponible qu'après un envoi réussi.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Envoyez d\u2019abord l\u2019invitation pour obtenir le lien')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lien copié')));
  }

  void _openQr() {
    if (_qrDataUri == null) _loadQr();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationQrScreen(
          guestName: row.guestName,
          status: _inv.status,
          code: _inv.invitationCode,
          qrDataUri: _qrDataUri,
          rsvpSummary: _rsvpCountText(_inv.status),
        ),
      ),
    );
  }

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
        title: Text('Détails de l\u2019invitation',
            style: InvType.appBarTitle(p.textPrimary)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, size: 24, color: p.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InvSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuestCard(context, p),
              const SizedBox(height: InvSpacing.lg),
              InvitationDetailsInfoCard(
                sentDate: _formatDate(_inv.sentAt),
                code: _inv.invitationCode.isEmpty ? '—' : _inv.invitationCode,
                status: _inv.status,
                publicLink: _publicLink,
                updatedDate: _formatDate(_inv.lastSentAt),
                onCopyLink: _copyLink,
              ),
              const SizedBox(height: InvSpacing.lg),
              InvitationQrCard(qrDataUri: _qrDataUri),
              const SizedBox(height: InvSpacing.xl),
              Text('Actions',
                  style: InvType.cardBody(p.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: InvSpacing.md),
              InvitationActionButton(
                label: 'Envoyer l\u2019invitation',
                icon: Icons.send_outlined,
                onTap: _busy ? null : _send,
              ),
              const SizedBox(height: InvSpacing.sm),
              InvitationActionButton(
                label: 'Renvoyer l\u2019invitation',
                icon: Icons.refresh_outlined,
                onTap: _busy ? null : _resend,
              ),
              const SizedBox(height: InvSpacing.sm),
              InvitationActionButton(
                label: 'Partager le lien',
                icon: Icons.share_outlined,
                onTap: _copyLink,
              ),
              const SizedBox(height: InvSpacing.sm),
              InvitationActionButton(
                label: 'Copier le lien',
                icon: Icons.copy_outlined,
                onTap: _copyLink,
              ),
              const SizedBox(height: InvSpacing.sm),
              InvitationActionButton(
                label: 'Afficher le QR Code',
                icon: Icons.qr_code_2,
                onTap: _openQr,
              ),
              const SizedBox(height: InvSpacing.sm),
              InvitationActionButton(
                label: 'Annuler l\u2019invitation',
                icon: Icons.block_outlined,
                destructive: true,
                onTap: _busy ? null : _confirmCancel,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context, InvPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InvSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.card),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: InvColors.primaryLight,
            child: Text(
              _initial(row.guestName),
              style: InvType.guestName(InvColors.primaryDark)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.guestName, style: InvType.guestNameStrong(p.textPrimary)),
                if (row.guestEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(row.guestEmail, style: InvType.cardMuted(p.textSecondary)),
                ],
                if (row.guestPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(row.guestPhone, style: InvType.cardMuted(p.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text(_maxText(), style: InvType.cardMuted(p.textSecondary)),
              ],
            ),
          ),
          InvitationStatusBadge(status: _inv.status),
        ],
      ),
    );
  }

  String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  String _maxText() {
    final m = row.maxPersons;
    return m > 1 ? '$m personnes autorisées' : '1 personne autorisée';
  }

  String _formatDate(String? s) {
    if (s == null || s.isEmpty) return 'Non envoyée';
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  String _rsvpCountText(String? status) {
    switch ((status ?? '').toUpperCase().trim()) {
      case 'DRAFT':
        return 'Brouillon';
      case 'GENERATED':
        return 'Prête à envoyer';
      case 'SENT':
        return 'Envoyée';
      case 'CANCELLED':
      case 'CANCELED':
        return 'Annulée';
      case 'EXPIRED':
        return 'Expirée';
      default:
        return '—';
    }
  }
}