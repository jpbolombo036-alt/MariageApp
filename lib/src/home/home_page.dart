import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_page.dart';
import '../auth/auth_models.dart';
import '../auth/auth_providers.dart';
import '../wedding/wedding_list_page.dart';

/// Page d'accueil après connexion : profil + accès modules (conditionnés par
/// le rôle/permissions ; le backend reste l'autorité).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final user = auth.user;

    final roles = (user?.roles ?? const []).join(', ');
    final canViewEvents = auth.hasPermission(PermissionCodes.weddingView);
    final isSuperAdmin = (user?.roles ?? const <String>[])
        .any((r) => r == 'SUPER_ADMIN');
    final itemCount = 1 + (canViewEvents ? 1 : 0) + (isSuperAdmin ? 1 : 0);
    var idx = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EventiaEasy'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(user?.email ?? ''),
                    const SizedBox(height: 8),
                    if (user?.organizationId != null)
                      Text('Organisation #${user!.organizationId}'),
                    Text('Rôles : ${roles.isEmpty ? '—' : roles}'),
                  ],
                ),
              ),
            );
          }

          if (canViewEvents && idx++ == 0) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.event)),
                title: const Text('Mes événements'),
                subtitle: const Text('Weddings, anniversaires, graduations...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeddingListPage()),
                ),
              ),
            );
          }

          if (isSuperAdmin) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
                title: const Text('Administration'),
                subtitle: const Text('Utilisateurs, rôles, organisations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}