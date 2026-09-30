import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';
import 'package:mariageplus_app/src/core/widgets/app_card.dart';

import 'admin_add_member_page.dart';
import 'admin_api.dart';
import 'admin_providers.dart';

class AdminOrganizationMembersPage extends ConsumerStatefulWidget {
  const AdminOrganizationMembersPage({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<AdminOrganizationMembersPage> createState() => _AdminOrganizationMembersPageState();
}

class _AdminOrganizationMembersPageState extends ConsumerState<AdminOrganizationMembersPage> {
  bool _loading = true;
  String? _error;
  List<OrgMember> _members = const [];
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
      final members = await api.listMembers(widget.organizationId);
      final roles = await api.listRoles();
      if (!mounted) return;
      setState(() {
        _members = members;
        _roles = roles;
        _loading = false;
      });
    } on AppFailure catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les membres';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les membres';
        _loading = false;
      });
    }
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminAddMemberPage(organizationId: widget.organizationId)),
    );
    await _load();
  }

  Future<void> _remove(OrgMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Retirer ${member.displayName} ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Retirer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminApiProvider).removeMember(widget.organizationId, member.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action refusée')));
    }
  }

  Future<void> _changeRole(OrgMember member) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Rôle de ${member.displayName}'),
        children: [
          for (final role in _roles)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(role.code),
              child: Text(role.code),
            ),
        ],
      ),
    );
    if (selected == null || selected == member.roleCode) return;
    try {
      await ref.read(adminApiProvider).updateMemberWedding(widget.organizationId, member.id, member.weddingId ?? 0);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action refusée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          IconButton(onPressed: _openAdd, icon: const Icon(Icons.add)),
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
              : _members.isEmpty
                  ? const Center(child: Text('Aucun membre'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return AppCard(
                          child: ListTile(
                            title: Text(member.displayName),
                            subtitle: Text('${member.email} · ${member.roleCode}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Changer le rôle',
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: () => _changeRole(member),
                                ),
                                IconButton(
                                  tooltip: 'Retirer',
                                  icon: const Icon(Icons.person_remove),
                                  onPressed: () => _remove(member),
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
