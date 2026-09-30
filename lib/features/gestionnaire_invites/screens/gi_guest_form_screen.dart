import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/guest/guest_api.dart';
import '../../../src/guest/guest_providers.dart';
import '../../../src/theme/gi_ui.dart';
import '../../../src/wedding/wedding_providers.dart';
import '../widgets/gi_nav.dart';

/// Champ de formulaire réutilisable du rôle GESTIONNAIRE_INVITES.
class GiFormField extends StatelessWidget {
  const GiFormField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.hint,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${required ? '*' : ''}$label',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: p.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: p.textSecondary),
            filled: true,
            fillColor: p.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GiRadius.field),
              borderSide: BorderSide(color: p.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GiRadius.field),
              borderSide: BorderSide(color: p.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GiRadius.field),
              borderSide: BorderSide(color: p.primary, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}
/// Formulaire Ajouter / Modifier un invité (rôle GESTIONNAIRE_INVITES).
class GiGuestFormScreen extends ConsumerStatefulWidget {
  const GiGuestFormScreen({super.key, this.edit});

  /// Invité existant, ou null pour une création.
  final Guest? edit;

  @override
  ConsumerState<GiGuestFormScreen> createState() => _GiGuestFormScreenState();
}

class _GiGuestFormScreenState extends ConsumerState<GiGuestFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companions = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;
  int? _weddingId;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      _firstName.text = e.firstName;
      _lastName.text = e.lastName;
      _email.text = e.email ?? '';
      _phone.text = e.phone ?? '';
      _companions.text = '${e.allowedCompanions ?? 0}';
      _notes.text = e.notes ?? '';
    }
    Future.microtask(_resolveWedding);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _companions.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _resolveWedding() async {
    try {
      final ws = await ref.read(weddingApiProvider).list(size: 1);
      if (mounted && ws.isNotEmpty) _weddingId = ws.first.id;
    } catch (_) {
      // Pas de mariage dispo → création impossible, on l'affichera.
    }
  }

  Future<void> _submit() async {
    final wid = _weddingId;
    if (wid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun événement disponible')));
      return;
    }
    final g = ref.read(guestApiProvider);
    setState(() => _submitting = true);
    try {
      final companions = int.tryParse(_companions.text.trim());
      final edit = widget.edit;
      if (edit != null) {
        await g.updateGuest(wid, edit.id, UpdateGuestRequest(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          allowedCompanions: companions,
          notes: _notes.text.trim(),
        ));
      } else {
        await g.createGuest(wid, CreateGuestRequest(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          allowedCompanions: companions,
          notes: _notes.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\u2019enregistrement')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = GiPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20, color: p.textPrimary)),
        title: Text(
            widget.edit == null ? 'Ajouter un invité' : 'Modifier l\u2019invité',
            style: TextStyle(color: p.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GiFormField(
              label: 'Prénom',
              required: true,
              controller: _firstName,
              hint: 'Ex. Marie'),
          const SizedBox(height: 16),
          GiFormField(
              label: 'Nom',
              required: true,
              controller: _lastName,
              hint: 'Ex. Dupont'),
          const SizedBox(height: 16),
          GiFormField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              hint: 'exemple@email.com'),
          const SizedBox(height: 16),
          GiFormField(
              label: 'Téléphone',
              controller: _phone,
              keyboardType: TextInputType.phone,
              hint: '+243 ...'),
          const SizedBox(height: 16),
          GiFormField(
              label: 'Nombre de personnes autorisées',
              controller: _companions,
              keyboardType: TextInputType.number,
              hint: '0'),
          const SizedBox(height: 16),
          GiFormField(
              label: 'Notes',
              controller: _notes,
              maxLines: 3,
              hint: 'Optionnel'),
          const SizedBox(height: 24),
          GiPrimaryButton(
            label: widget.edit == null
                ? 'Enregistrer l\u2019invité'
                : 'Mettre à jour',
            icon: Icons.check,
            onTap: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ]),
      ),
    );
  }
}