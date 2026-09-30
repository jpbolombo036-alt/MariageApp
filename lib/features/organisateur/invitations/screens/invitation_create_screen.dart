import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/guest/guest_api.dart';
import '../../../../src/guest/guest_providers.dart';
import '../../../../src/invitation/invitation_api.dart';
import '../../../../src/invitation/invitation_providers.dart';
import '../../../../src/theme/invitation_ui.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';
import '../widgets/step_guest.dart';

/// Écran « Nouvelle invitation » — formulaire en 3 étapes.
///
/// Si [weddingId] est fourni, l'invitation porte sur cet événement ; sinon le
/// premier événement de l'utilisateur est utilisé (comportement historique des
/// modules sans sélecteur d'événement).
class InvitationCreateScreen extends ConsumerStatefulWidget {
  const InvitationCreateScreen({super.key, this.weddingId});

  /// Événement ciblé (facultatif).
  final int? weddingId;

  @override
  ConsumerState<InvitationCreateScreen> createState() =>
      _InvitationCreateScreenState();
}

class _InvitationCreateScreenState extends ConsumerState<InvitationCreateScreen> {
  static const _steps = ['Invité', 'Détails', 'Confirmation'];

  int _step = 0;
  bool _loading = true;
  String? _error;
  Wedding? _wedding;
  List<Guest> _guests = const [];
  Guest? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weddingApi = ref.read(weddingApiProvider);
      final targetId = widget.weddingId;
      late final Wedding wedding;
      if (targetId != null) {
        wedding = await weddingApi.getById(targetId);
      } else {
        final weddings = await weddingApi.list(size: 25);
        if (!mounted) return;
        if (weddings.isEmpty) {
          setState(() {
            _loading = false;
            _wedding = null;
          });
          return;
        }
        wedding = weddings.first;
      }
      final guests = await ref
          .read(guestApiProvider)
          .listGuests(wedding.id, size: 200);
      if (!mounted) return;
      setState(() {
        _wedding = wedding;
        _guests = guests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger l\'événement et ses invités';
      });
    }
  }

  Future<void> _create() async {
    final w = _wedding;
    final g = _selected;
    if (w == null || g == null) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(invitationApiProvider)
          .create(w.id, CreateInvitationRequest(guestId: g.id));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  /// Message lisible : le détail renvoyé par le backend prime.
  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      final code = error.response?.statusCode;
      switch (code) {
        case 400:
          return 'Données invalides : vérifiez l\'invité sélectionné';
        case 403:
          return 'Action non autorisée pour votre rôle';
        case 404:
          return 'Invité ou événement introuvable';
        case 409:
          return 'Une invitation existe déjà pour cet invité';
      }
      return 'Impossible de créer l\'invitation (${code ?? 'réseau'})';
    }
    return 'Impossible de créer l\'invitation';
  }

  Future<void> _pickGuest() async {
    final picked = await showModalBottomSheet<Guest>(
      context: context,
      backgroundColor: InvPalette.of(context).surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _GuestPickerSheet(guests: _guests),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  String _maxText(Guest g) {
    final m = g.allowedCompanions != null ? 1 + g.allowedCompanions! : 1;
    return m > 1 ? '$m personnes max' : '1 personne max';
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
          onPressed: _step > 0
              ? () => setState(() => _step--)
              : () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, size: 22, color: p.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle invitation',
                style: InvType.appBarTitle(p.textPrimary)),
            Text('Créez une invitation pour un invité',
                style: InvType.subtitle(p.textSecondary)),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: InvColors.primary))
            : _error != null
                ? const Center(child: Text('Impossible de charger les données'))
                : _wedding == null
                    ? const Center(child: Text('Aucun événement disponible'))
                    : _buildForm(context, p),
      ),
    );
  }

  Widget _buildForm(BuildContext context, InvPalette p) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: InvSpacing.lg),
          child: StepProgressIndicator(steps: _steps, current: _step),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: InvSpacing.lg),
            child: _buildStepContent(context, p),
          ),
        ),
        _buildActions(p),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, InvPalette p) {
    switch (_step) {
      case 0:
        return _stepGuest(p);
      case 1:
        return _stepDetails(p);
      case 2:
        return _stepConfirm(p);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepGuest(InvPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invité *',
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickGuest,
          borderRadius: BorderRadius.circular(InvRadius.field),
          child: Container(
            width: double.infinity,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(InvRadius.field),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: p.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selected == null
                        ? 'Sélectionner un invité...'
                        : '${_selected!.firstName} ${_selected!.lastName}',
                    style: InvType.cardBody(
                        _selected == null ? p.textTertiary : p.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.expand_more, size: 22, color: p.textSecondary),
              ],
            ),
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: InvSpacing.lg),
          SelectedGuestCard(
            name: '${_selected!.firstName} ${_selected!.lastName}',
            email: _selected!.email,
            phone: _selected!.phone,
            persons: _maxText(_selected!),
            category: _selected!.categoryId != null
                ? 'Catégorie #${_selected!.categoryId}'
                : null,
          ),
        ],
        const SizedBox(height: InvSpacing.lg),
        Text('Résumé',
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_selected == null)
          Text('Aucun invité sélectionné pour le moment.',
              style: InvType.cardMuted(p.textSecondary))
        else ...[
          Text(
            'Une invitation sera créée pour ${_selected!.firstName} ${_selected!.lastName}.',
            style: InvType.cardBody(p.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Elle pourra accéder à l\u2019événement avec ${_maxText(_selected!)}.',
            style: InvType.cardBody(p.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _stepDetails(InvPalette p) {
    final g = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détails de l\u2019invitation',
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'L\u2019invitation porte sur '
          '${g != null ? '${g.firstName} ${g.lastName}' : 'l\u2019invité sélectionné'}.',
          style: InvType.cardBody(p.textSecondary),
        ),
        const SizedBox(height: 16),
        if (g != null) ...[
          _infoTile(p, Icons.group_outlined, 'Personnes', _maxText(g)),
          const SizedBox(height: 10),
          _infoTile(
            p,
            Icons.category_outlined,
            'Catégorie',
            g.categoryId != null ? 'Catégorie #${g.categoryId}' : '—',
          ),
        ],
      ],
    );
  }

  Widget _infoTile(InvPalette p, IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(InvRadius.field),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: InvColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: InvType.cardBody(p.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Text(value, style: InvType.cardBody(p.textSecondary)),
      ]),
    );
  }

  Widget _stepConfirm(InvPalette p) {
    final g = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirmation',
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          g == null
              ? 'Aucun invité sélectionné.'
              : 'Une invitation sera créée pour '
                  '${g.firstName} ${g.lastName} avec ${_maxText(g)}.',
          style: InvType.cardBody(p.textSecondary),
        ),
        const SizedBox(height: 24),
        const Center(
            child: Icon(Icons.mark_email_read_outlined,
                size: 64, color: InvColors.primary)),
        const SizedBox(height: 12),
        Text('Prêt à créer l\u2019invitation ?',
            textAlign: TextAlign.center,
            style: InvType.cardBody(p.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActions(InvPalette p) {
    final isLast = _step == _steps.length - 1;
    final canProceed = _step > 0 || _selected != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(InvSpacing.lg, 12, InvSpacing.lg, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _submitting || !canProceed
              ? null
              : isLast
                  ? _create
                  : () => setState(() => _step++),
          style: FilledButton.styleFrom(
            backgroundColor: InvColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvRadius.button)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4))
              : Text(isLast ? 'Créer l\u2019invitation' : 'Suivant',
                  style: InvType.button(Colors.white)),
        ),
      ),
    );
  }
}

/// Feuille de sélection d'un invité.
class _GuestPickerSheet extends StatelessWidget {
  const _GuestPickerSheet({required this.guests});

  final List<Guest> guests;

  @override
  Widget build(BuildContext context) {
    final p = InvPalette.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sélectionner un invité',
                  style: InvType.guestNameStrong(p.textPrimary)),
            ),
            const Divider(height: 1, color: null),
            Expanded(
              child: guests.isEmpty
                  ? Center(
                      child: Text('Aucun invité disponible',
                          style: InvType.cardMuted(p.textSecondary)))
                  : ListView.separated(
                      itemCount: guests.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: p.border),
                      itemBuilder: (context, i) {
                        final g = guests[i];
                        final m = g.allowedCompanions != null
                            ? 1 + g.allowedCompanions!
                            : 1;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: InvColors.primaryLight,
                            child: Text(
                              g.firstName.trim().isEmpty
                                  ? '?'
                                  : g.firstName
                                      .trim()
                                      .characters
                                      .first
                                      .toUpperCase(),
                              style: const TextStyle(
                                  color: InvColors.primaryDark,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text('${g.firstName} ${g.lastName}',
                              style: InvType.cardBody(p.textPrimary)),
                          subtitle: Text('$m personne(s)',
                              style: InvType.cardMuted(p.textSecondary)),
                          onTap: () => Navigator.of(context).pop(g),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
