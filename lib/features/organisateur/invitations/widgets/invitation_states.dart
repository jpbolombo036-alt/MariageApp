import 'package:flutter/material.dart';

import '../../../../src/theme/invitation_ui.dart';

/// État vide : aucune invitation pour l'instant.
class EmptyInvitationsState extends StatelessWidget {
  const EmptyInvitationsState({super.key, this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: InvColors.primaryVeryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_outline,
                  size: 42, color: InvColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              'Aucune invitation pour le moment',
              textAlign: TextAlign.center,
              style: InvType.screenTitle(p.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Créez votre première invitation pour commencer à inviter vos proches.',
              textAlign: TextAlign.center,
              style: InvType.cardBody(p.textSecondary),
            ),
            const SizedBox(height: 24),
            if (onCreate != null)
              SizedBox(
                width: 240,
                height: 52,
                child: _GradientButton(label: 'Nouvelle invitation', onTap: onCreate),
              ),
          ],
        ),
      ),
    );
  }
}

/// État : chargement discret (spinner violet).
class InvitationLoadingState extends StatelessWidget {
  const InvitationLoadingState({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 34,
        height: 34,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: InvColors.primary,
        ),
      ),
    );
  }
}

/// État : erreur réseau avec bouton « Réessayer ».
class InvitationErrorState extends StatelessWidget {
  const InvitationErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: p.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les invitations',
              textAlign: TextAlign.center,
              style: InvType.guestName(p.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion puis réessayez.',
              textAlign: TextAlign.center,
              style: InvType.cardMuted(p.textSecondary),
            ),
            const SizedBox(height: 20),
            if (onRetry != null)
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: InvColors.primary,
                  side: const BorderSide(color: InvColors.primary),
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(InvRadius.field),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }
}

/// État : recherche sans résultat.
class NoInvitationResultsState extends StatelessWidget {
  const NoInvitationResultsState({super.key});
  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: p.textTertiary),
          const SizedBox(height: 12),
          Text(
            'Aucune invitation trouvée',
            style: InvType.guestName(p.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Bouton principal dégradé violet (réutilisé par les états et l'écran liste).
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(gradient: invPrimaryGradient, borderRadius: BorderRadius.circular(InvRadius.pill)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(InvRadius.pill),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(child: Text(label, style: InvType.button(Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}