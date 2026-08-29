import 'package:flutter/material.dart';

import 'auth_controller.dart';
import 'auth_models.dart';

/// Écran combiné connexion / inscription.
///
/// Reçoit le [AuthController] depuis le parent (qui le lit via Riverpod).
/// Expose un formulaire à bascule login/register et rejoint la page d'accueil
/// automatiquement (le parent réagit à `isAuthenticated`).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _organizationNameController = TextEditingController();

  bool _registerMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final AuthController c = widget.controller;
    final AuthResult result;
    if (_registerMode) {
      result = await c.register(RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        organizationName: _organizationNameController.text.trim(),
      ));
    } else {
      result = await c.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = result.isSuccess ? null : (result.error ?? 'Une erreur est survenue');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MariagePlus'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _registerMode ? 'Créer un compte' : 'Connexion',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_registerMode) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _organizationNameController,
                  decoration: const InputDecoration(labelText: 'Organisation'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.trim().contains('@')) ? 'Email invalide' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
              ),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_registerMode ? "S'inscrire" : 'Se connecter'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _registerMode = !_registerMode),
                child: Text(_registerMode
                    ? 'J’ai déjà un compte'
                    : 'Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}