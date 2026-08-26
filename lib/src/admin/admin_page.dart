import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_api.dart';
import 'admin_providers.dart';

/// Section active de l'écran admin.
enum _AdminTab {
  users,
  roles,
  organizations,
}

/// Écran administration (SUPER_ADMIN) : utilisateurs, rôles, organisations.
/// L'accès est conditionné par le rôle (le backend reste l'autorité via
/// `hasRole('SUPER_ADMIN')` sur les endpoints).
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  _AdminTab _tab = _AdminTab.users;

  bool _loading = true;
  String? _error;
  List<AdminUser> _users = const [];
  List<AdminRole> _roles = const [];
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
      final users = await api.listUsers();
      final roles = await api.listRoles();
      final orgs = await api.listOrganizations();
      if (!mounted) return;
      setState(() {
        _users = users;
        _roles = roles;
        _organizations = orgs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les données admin';
        _loading = false;
      });
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
          ? FilledButton(
              onPressed: () => setState(() => _tab = tab),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: () => setState(() => _tab = tab),
              child: Text(label),
            ),
    );
  }

  Widget _buildTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _buildTabList(),
    );
  }

  Widget _buildTabList() {
    const padding = EdgeInsets.all(12);
    return switch (_tab) {
      _AdminTab.users => ListView(
          padding: padding,
          children: [
            for (final u in _users) _userCard(u),
          ],
        ),
      _AdminTab.roles => ListView(
          padding: padding,
          children: [
            for (final r in _roles) _roleCard(r),
          ],
        ),
      _AdminTab.organizations => ListView(
          padding: padding,
          children: [
            for (final o in _organizations) _organizationCard(o),
          ],
        ),
    };
  }

  Widget _userCard(AdminUser u) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(u.active ? Icons.person : Icons.person_off)),
        title: Text(u.displayName),
        subtitle: Text(
          '${u.email} · ${u.roles.join(', ')}'
          '${u.organizationId != null ? ' · Org #${u.organizationId}' : ''}',
        ),
      ),
    );
  }

  Widget _roleCard(AdminRole r) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.security)),
        title: Text(r.code),
        subtitle: Text(
          '${r.permissionCodes.length} permission(s)'
          '${r.active ? '' : ' · inactif'}',
        ),
      ),
    );
  }

  Widget _organizationCard(AdminOrganization o) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: const Icon(Icons.business)),
        title: Text(o.name),
        subtitle: Text(
          '${o.email ?? '—'} · ${o.active ? 'active' : 'inactive'}',
        ),
      ),
    );
  }
}