import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_card.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminUserRolesPage extends ConsumerStatefulWidget {
  const AdminUserRolesPage({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<AdminUserRolesPage> createState() => _AdminUserRolesPageState();
}

class _AdminUserRolesPageState extends ConsumerState<AdminUserRolesPage> {
  bool _loading = true;
  String? _error;
  List<AdminRole> _roles = const [];
  Set<int> _selectedRoleIds = const {};

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
      final roles = await api.listRoles();
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _loading = false;
      });
    } on AppFailure catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les rôles';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les rôles';
        _loading = false;
      });
    }
  }

  Future<void> _toggleRole(AdminRole role) async {
    if (_selectedRoleIds.contains(role.id)) {
      try {
        await ref.read(adminApiProvider).removeRoleFromUser(widget.userId, role.id);
        setState(() => _selectedRoleIds = _selectedRoleIds.where((id) => id != role.id).toSet());
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action refusée')));
      }
    } else {
      try {
        await ref.read(adminApiProvider).assignRoleToUser(widget.userId, AdminAssignRoleRequest(roleCode: role.code));
        setState(() => _selectedRoleIds = {..._selectedRoleIds, role.id});
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action refusée')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rôles de l’utilisateur')),
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
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final selected = _selectedRoleIds.contains(role.id);
                    return AppCard(
                      onTap: () => _toggleRole(role),
                      child: CheckboxListTile(
                        value: selected,
                        title: Text(role.code),
                        subtitle: Text('${role.permissionCodes.length} permission(s)'),
                        onChanged: (_) => _toggleRole(role),
                      ),
                    );
                  },
                ),
    );
  }
}
