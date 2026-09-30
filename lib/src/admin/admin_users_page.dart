import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_card.dart';
import 'package:mariageplus_app/src/auth/auth_models.dart';

import '../auth/auth_providers.dart';
import 'admin_api.dart';
import 'admin_providers.dart';
import 'admin_user_form_page.dart';
import 'admin_user_roles_page.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  bool _loading = true;
  String? _error;
  List<AdminUser> _users = const [];

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
      final users = await api.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger les utilisateurs');
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminUserFormPage()),
    );
    await _load();
  }

  Future<void> _openEdit(AdminUser user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminUserFormPage(user: user)),
    );
    await _load();
  }

  Future<void> _toggleActive(AdminUser user) async {
    try {
      await ref.read(adminApiProvider).toggleUserActive(user.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte non modifié')),
      );
    }
  }

  Future<void> _manageRoles(AdminUser user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminUserRolesPage(userId: user.id)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = ref.watch(authControllerProvider).hasPermission(PermissionCodes.organizationManageMembers);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          if (canCreate)
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
              : _users.isEmpty
                  ? const Center(child: Text('Aucun utilisateur'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return AppCard(
                          onTap: () => _openEdit(user),
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(user.active ? Icons.person : Icons.person_off)),
                            title: Text(user.displayName),
                            subtitle: Text('${user.email} · ${user.roles.join(', ')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Rôles',
                                  icon: const Icon(Icons.security),
                                  onPressed: () => _manageRoles(user),
                                ),
                                Switch(
                                  value: user.active,
                                  onChanged: (_) => _toggleActive(user),
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
