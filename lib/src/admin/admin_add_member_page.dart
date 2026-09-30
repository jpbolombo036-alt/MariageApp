import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_button.dart';
import 'package:mariageplus_app/src/core/widgets/app_text_field.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminAddMemberPage extends ConsumerStatefulWidget {
  const AdminAddMemberPage({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<AdminAddMemberPage> createState() => _AdminAddMemberPageState();
}

class _AdminAddMemberPageState extends ConsumerState<AdminAddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _roleCode = 'ORGANISATEUR';
  List<AdminRole> _roles = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final api = ref.read(adminApiProvider);
      final roles = await api.listRoles();
      if (!mounted) return;
      setState(() => _roles = roles);
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
      await api.addOrganizationMember(widget.organizationId, AdminAddMemberRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        password: _passwordController.text,
        roleCode: _roleCode,
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Ajout impossible');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un membre')),
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
            AppTextField(controller: _passwordController, label: 'Mot de passe', obscureText: true, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _roleCode,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: [
                for (final role in _roles)
                  DropdownMenuItem(value: role.code, child: Text(role.code)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _roleCode = v);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            AppButton(label: 'Ajouter', loading: _loading, fullWidth: true, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
