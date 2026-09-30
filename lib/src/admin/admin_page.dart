import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_providers.dart';
import 'admin_organizations_page.dart';
import 'admin_roles_page.dart';
import 'admin_users_page.dart';

enum _AdminTab { users, roles, organizations }

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  _AdminTab _tab = _AdminTab.users;
  bool _eventCreation = true;

  @override
  void initState() {
    super.initState();
    _loadEventCreation();
  }

  Future<void> _loadEventCreation() async {
    try {
      final value = await ref.read(adminApiProvider).getAdminEventCreation();
      if (!mounted) return;
      setState(() => _eventCreation = value);
    } catch (_) {}
  }

  Future<void> _setEventCreation(bool value) async {
    try {
      final next = await ref.read(adminApiProvider).updateAdminEventCreation(value);
      if (!mounted) return;
      setState(() => _eventCreation = next);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réglage non enregistré')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _tabButton(_AdminTab.users, 'Utilisateurs'),
                _tabButton(_AdminTab.roles, 'Rôles'),
                _tabButton(_AdminTab.organizations, 'Organisations'),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Création d’événements'),
            subtitle: const Text('Interrupteur global de la plateforme'),
            value: _eventCreation,
            onChanged: _setEventCreation,
          ),
          Expanded(child: _buildTab()),
        ],
      ),
    );
  }

  Widget _tabButton(_AdminTab tab, String label) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: selected
          ? FilledButton(onPressed: () => setState(() => _tab = tab), child: Text(label))
          : OutlinedButton(onPressed: () => setState(() => _tab = tab), child: Text(label)),
    );
  }

  Widget _buildTab() {
    return switch (_tab) {
      _AdminTab.users => const AdminUsersPage(),
      _AdminTab.roles => const AdminRolesPage(),
      _AdminTab.organizations => const AdminOrganizationsPage(),
    };
  }
}
