import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_button.dart';
import 'package:mariageplus_app/src/core/widgets/app_text_field.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminRoleFormPage extends ConsumerStatefulWidget {
  const AdminRoleFormPage({super.key, this.role});

  final AdminRole? role;

  @override
  ConsumerState<AdminRoleFormPage> createState() => _AdminRoleFormPageState();
}

class _AdminRoleFormPageState extends ConsumerState<AdminRoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    _codeController.text = role?.code ?? '';
    _descriptionController.text = role?.description ?? '';
    _active = role?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
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
      if (widget.role == null) {
        await api.createRole(AdminCreateRoleRequest(
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          active: _active,
        ));
      } else {
        await api.updateRole(widget.role!.id, AdminUpdateRoleRequest(
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
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
    final isEdit = widget.role != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Modifier le rôle' : 'Nouveau rôle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(controller: _codeController, label: 'Code', validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(controller: _descriptionController, label: 'Description'),
            const SizedBox(height: 12),
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
