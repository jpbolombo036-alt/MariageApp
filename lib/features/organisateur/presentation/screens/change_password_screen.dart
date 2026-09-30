import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/auth/auth_providers.dart';
import '../../../../src/theme/app_theme.dart';

/// Écran « Changer le mot de passe » (rôle ORGANISATEUR, depuis le menu Plus).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Les nouveaux mots de passe ne correspondent pas')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .changePassword(oldPassword: _old.text, newPassword: _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ancien mot de passe incorrect')));
    }
  }

  @override
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
        title: const Text('Changer le mot de passe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(scheme, _old, 'Ancien mot de passe', obscure: true),
              const SizedBox(height: 16),
              _field(scheme, _new, 'Nouveau mot de passe', obscure: true,
                  validator: (v) => (v == null || v.length < 8)
                      ? '8 caractères minimum'
                      : null),
              const SizedBox(height: 16),
              _field(scheme, _confirm, 'Confirmer le nouveau mot de passe',
                  obscure: true),
              const SizedBox(height: 24),
              SizedBox(
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
                      : const Text('Enregistrer',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(ColorScheme scheme, TextEditingController c, String label,
      {required bool obscure, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      style: TextStyle(fontSize: 14, color: scheme.onSurface),
      validator: validator ??
          ((v) => (v == null || v.isEmpty) ? 'Requis' : null),
      decoration: InputDecoration(labelText: label),
    );
  }
}