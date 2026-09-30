import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_card.dart';
import 'package:mariageplus_app/src/auth/auth_models.dart';

import '../auth/auth_providers.dart';
import 'admin_api.dart';
import 'admin_providers.dart';
import 'admin_organization_form_page.dart';
import 'admin_organization_members_page.dart';
import 'admin_organization_settings_page.dart';

class AdminOrganizationsPage extends ConsumerStatefulWidget {
  const AdminOrganizationsPage({super.key});

  @override
  ConsumerState<AdminOrganizationsPage> createState() => _AdminOrganizationsPageState();
}

class _AdminOrganizationsPageState extends ConsumerState<AdminOrganizationsPage> {
  bool _loading = true;
  String? _error;
  List<AdminOrganization> _organizations = const [];

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
      final api = ref.read(adminApiProvider);
      final orgs = await api.listOrganizations();
      if (!mounted) return;
      setState(() {
        _organizations = orgs;
        _loading = false;
      });
    } on AppFailure catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les organisations';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les organisations';
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminOrganizationFormPage()),
    );
    await _load();
  }

  Future<void> _openEdit(AdminOrganization org) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminOrganizationFormPage(organization: org)),
    );
    await _load();
  }

  Future<void> _toggleActive(AdminOrganization org) async {
    try {
      await ref.read(adminApiProvider).toggleOrganizationActive(org.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organisation non modifiée')));
    }
  }

  Future<void> _settings(AdminOrganization org) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminOrganizationSettingsPage(organization: org)),
    );
    await _load();
  }

  Future<void> _members(AdminOrganization org) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminOrganizationMembersPage(organizationId: org.id)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(authControllerProvider).hasPermission(PermissionCodes.organizationManageMembers);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisations'),
        actions: [
          if (canManage)
            IconButton(onPressed: _openCreate, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _organizations.isEmpty
                  ? const Center(child: Text('Aucune organisation'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _organizations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final org = _organizations[index];
                        return AppCard(
                          onTap: () => _openEdit(org),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.business)),
                            title: Text(org.name),
                            subtitle: Text('${org.email ?? '—'} · ${org.active ? 'active' : 'inactive'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Membres',
                                  icon: const Icon(Icons.group),
                                  onPressed: () => _members(org),
                                ),
                                IconButton(
                                  tooltip: 'Réglages',
                                  icon: const Icon(Icons.tune),
                                  onPressed: () => _settings(org),
                                ),
                                Switch(
                                  value: org.active,
                                  onChanged: (_) => _toggleActive(org),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
