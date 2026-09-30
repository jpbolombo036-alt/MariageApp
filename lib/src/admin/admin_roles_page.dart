import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_card.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

class AdminRolesPage extends ConsumerStatefulWidget {
  const AdminRolesPage({super.key});

  @override
  ConsumerState<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends ConsumerState<AdminRolesPage> {
  bool _loading = true;
  String? _error;
  List<AdminRole> _roles = const [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rôles')),
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
              : _roles.isEmpty
                  ? const Center(child: Text('Aucun rôle'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _roles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        return AppCard(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.security)),
                            title: Text(role.code),
                            subtitle: Text('${role.permissionCodes.length} permission(s) · ${role.active ? 'actif' : 'inactif'}'),
                            trailing: Icon(Icons.security),
                          ),
                        );
                      },
                    ),
    );
  }
}
