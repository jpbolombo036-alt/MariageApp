import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_button.dart';
import 'package:mariageplus_app/src/core/widgets/app_text_field.dart';

import '../auth/auth_providers.dart';
import 'admin_api.dart';
import 'admin_providers.dart';

class AdminUserFormPage extends ConsumerStatefulWidget {
  const AdminUserFormPage({super.key, this.user});

  final AdminUser? user;

  @override
  ConsumerState<AdminUserFormPage> createState() => _AdminUserFormPageState();
}

class _AdminUserFormPageState extends ConsumerState<AdminUserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _active = user?.active ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(adminApiProvider);
      if (widget.user == null) {
        if (_passwordController.text.isEmpty) {
          throw const ValidationFailure(errors: {'password': 'Mot de passe requis'});
        }
        if (_passwordController.text != _passwordConfirmController.text) {
          throw const ValidationFailure(errors: {'password_confirm': 'Les mots de passe ne correspondent pas'});
        }
        await api.createUser(
          AdminCreateUserRequest(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            password: _passwordController.text,
            organizationId: ref.read(authControllerProvider).user?.organizationId,
          ),
        );
      } else {
        await api.updateUser(widget.user!.id, AdminUpdateUserRequest(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          active: _active,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Enregistrement impossible');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Modifier l’utilisateur' : 'Nouvel utilisateur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(controller: _firstNameController, label: 'Prénom', validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(controller: _lastNameController, label: 'Nom', validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(controller: _phoneController, label: 'Téléphone'),
            const SizedBox(height: 12),
            if (!isEdit) ...[
              AppTextField(controller: _passwordController, label: 'Mot de passe', obscureText: true, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
              const SizedBox(height: 12),
              AppTextField(controller: _passwordConfirmController, label: 'Confirmer le mot de passe', obscureText: true),
              const SizedBox(height: 12),
            ],
            SwitchListTile(title: const Text('Actif'), value: _active, onChanged: (v) => setState(() => _active = v)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            AppButton(label: isEdit ? 'Enregistrer' : 'Créer', loading: _loading, fullWidth: true, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
