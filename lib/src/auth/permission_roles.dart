import 'auth_models.dart';

/// Dérive les permissions d'affichage à partir des rôles de l'utilisateur.
///
/// NB : ceci ne sert qu'à masquer/afficher des actions côté UI. La sécurité
/// réelle (RBAC + isolation par organisation) est **toujours** vérifiée par le
/// backend, quel que soit l'affichage local.
List<String> permissionsForRoles(List<String> roles) {
  if (roles.any((r) => r == 'SUPER_ADMIN')) {
    return superPermissions();
  }
  if (roles.any((r) => r == 'ORGANISATEUR')) {
    return organizatorPermissions();
  }
  if (roles.any((r) => r == 'GESTIONNAIRE_INVITES')) {
    return [
      PermissionCodes.weddingView,
      PermissionCodes.guestView,
      PermissionCodes.guestCreate,
      PermissionCodes.guestUpdate,
      PermissionCodes.categoryView,
      PermissionCodes.invitationView,
      PermissionCodes.invitationCreate,
    ];
  }
  if (roles.any((r) => r == 'AGENT_ACCUEIL')) {
    return [
      PermissionCodes.weddingView,
      PermissionCodes.invitationView,
      PermissionCodes.checkinCreate,
    ];
  }
  return [];
}

List<String> superPermissions() => [
      PermissionCodes.weddingView,
      PermissionCodes.weddingCreate,
      PermissionCodes.weddingUpdate,
      PermissionCodes.weddingDelete,
      PermissionCodes.weddingPublish,
      PermissionCodes.weddingArchive,
      PermissionCodes.dashboardView,
      PermissionCodes.guestView,
      PermissionCodes.guestCreate,
      PermissionCodes.guestUpdate,
      PermissionCodes.guestDelete,
      PermissionCodes.categoryView,
      PermissionCodes.categoryCreate,
      PermissionCodes.invitationView,
      PermissionCodes.invitationCreate,
      PermissionCodes.checkinCreate,
      PermissionCodes.tableCreate,
      PermissionCodes.organizationManageMembers,
    ];

List<String> organizatorPermissions() => [
      PermissionCodes.weddingView,
      PermissionCodes.weddingCreate,
      PermissionCodes.weddingUpdate,
      PermissionCodes.weddingDelete,
      PermissionCodes.dashboardView,
      PermissionCodes.guestView,
      PermissionCodes.guestCreate,
      PermissionCodes.guestUpdate,
      PermissionCodes.guestDelete,
      PermissionCodes.categoryView,
      PermissionCodes.categoryCreate,
      PermissionCodes.invitationView,
      PermissionCodes.invitationCreate,
      PermissionCodes.tableCreate,
      PermissionCodes.organizationManageMembers,
    ];

/// Permissions d'affichage : codes renvoyés par l'API si présents,
/// sinon matrice locale dérivée des rôles.
List<String> permissionsFromPayload(
  Map<String, dynamic> json,
  List<String> roles,
) {
  final codes = <String>{
    ..._permissionCodes(json['permissions']),
    ..._permissionCodes(json['authorities']),
  };
  final user = json['user'];
  if (user is Map) {
    codes.addAll(_permissionCodes(user['permissions']));
    codes.addAll(_permissionCodes(user['authorities']));
  }
  if (codes.isEmpty) return permissionsForRoles(roles);
  return codes.toList();
}

Iterable<String> _permissionCodes(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((entry) {
    if (entry is String) return entry;
    if (entry is Map) {
      final code = entry['code'] ?? entry['name'];
      if (code != null) return code.toString();
    }
    return '';
  }).where((code) => code.isNotEmpty);
}

/// Alias entre les codes Wedding historiques et les codes Event du backend.
String? permissionAlias(String code) => switch (code) {
      PermissionCodes.weddingView => PermissionCodes.eventView,
      PermissionCodes.weddingCreate => PermissionCodes.eventCreate,
      PermissionCodes.weddingUpdate => PermissionCodes.eventUpdate,
      PermissionCodes.weddingDelete => PermissionCodes.eventDelete,
      PermissionCodes.eventView => PermissionCodes.weddingView,
      PermissionCodes.eventCreate => PermissionCodes.weddingCreate,
      PermissionCodes.eventUpdate => PermissionCodes.weddingUpdate,
      PermissionCodes.eventDelete => PermissionCodes.weddingDelete,
      _ => null,
    };