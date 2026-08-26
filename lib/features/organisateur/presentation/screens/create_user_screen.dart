import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/admin/admin_api.dart';
import '../../../../src/admin/admin_providers.dart';
import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_theme.dart';

/// Rôles qu'un ORGANISATEUR peut attribuer à un membre de son équipe.
const kOrganizerRoles = [
  ('GESTIONNAIRE_INVITES', 'Gestionnaire invités'),
  ('AGENT_ACCUEIL', 'Agent accueil'),
];

/// Formulaire « Ajouter un membre » de l'équipe (rôle ORGANISATEUR).
class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _roleCode;
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez un rôle pour ce membre')));
      return;
    }
    final orgId = ref.read(authControllerProvider).user?.organizationId;
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune organisation définie pour votre compte')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(adminApiProvider).addOrganizationMember(orgId,
          AdminAddMemberRequest(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            password: _password.text,
            roleCode: _roleCode!,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Membre ajouté à l\u2019équipe')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur : vérifiez les informations')));
    }
  }@override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, size: 22, color: scheme.onSurface),
        ),
        title: const Text('Ajouter un membre',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _intro(scheme),
              const SizedBox(height: 20),
              _label(scheme, 'Prénom *'),
              _field(scheme, _firstName, 'Ex. Marie'),
              const SizedBox(height: 14),
              _label(scheme, 'Nom *'),
              _field(scheme, _lastName, 'Ex. Dupont'),
              const SizedBox(height: 14),
              _label(scheme, 'Email *'),
              _field(scheme, _email, 'exemple@email.com'),
              const SizedBox(height: 14),
              _label(scheme, 'Téléphone'),
              _field(scheme, _phone, '+243 ...'),
              const SizedBox(height: 14),
              _label(scheme, 'Mot de passe *'),
              _field(scheme, _password, '8 caractères min', obscure: true),
              const SizedBox(height: 20),
              _label(scheme, 'Rôle *'),
              _roleSelector(scheme),
              const SizedBox(height: 24),
              _submitButton(scheme),
            ]),
          ),
        ),
      ),
    );
  }
Widget _intro(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.groups_outlined, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Un nouveau membre pourra se connecter et gérer votre événement selon son rôle.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ]),
    );
  }

  Widget _label(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
    );
  }

  Widget _field(ColorScheme scheme, TextEditingController c, String hint,
      {TextInputType? keyboardType, bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: scheme.onSurface),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
    );
  }
Widget _roleSelector(ColorScheme scheme) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (code, label) in kOrganizerRoles)
          _roleChip(scheme, code, label),
      ],
    );
  }

  Widget _roleChip(ColorScheme scheme, String code, String label) {
    final selected = _roleCode == code;
    return InkWell(
      onTap: () => setState(() => _roleCode = code),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) ...[
            Icon(Icons.check, size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : scheme.onSurface)),
        ]),
      ),
    );
  }

  Widget _submitButton(ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _submitting ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
        child: _submitting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : const Text('Ajouter le membre',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }
}