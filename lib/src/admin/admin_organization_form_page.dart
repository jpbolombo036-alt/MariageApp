import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_button.dart';
import 'package:mariageplus_app/src/core/widgets/app_text_field.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminOrganizationFormPage extends ConsumerStatefulWidget {
  const AdminOrganizationFormPage({super.key, this.organization});

  final AdminOrganization? organization;

  @override
  ConsumerState<AdminOrganizationFormPage> createState() => _AdminOrganizationFormPageState();
}

class _AdminOrganizationFormPageState extends ConsumerState<AdminOrganizationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _loading = false;
  String? _error;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _nameController = TextEditingController(text: org?.name ?? '');
    _emailController = TextEditingController(text: org?.email ?? '');
    _phoneController = TextEditingController(text: org?.phone ?? '');
    _addressController = TextEditingController(text: org?.address ?? '');
    _active = org?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
      if (widget.organization == null) {
        await api.createOrganization(AdminCreateOrganizationRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        ));
      } else {
        await api.updateOrganization(widget.organization!.id, AdminUpdateOrganizationRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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
    final isEdit = widget.organization != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Modifier l’organisation' : 'Nouvelle organisation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(controller: _nameController, label: 'Nom', validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppTextField(controller: _phoneController, label: 'Téléphone'),
            const SizedBox(height: 12),
            AppTextField(controller: _addressController, label: 'Adresse'),
            const SizedBox(height: 12),
            SwitchListTile(title: const Text('Active'), value: _active, onChanged: (v) => setState(() => _active = v)),
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
