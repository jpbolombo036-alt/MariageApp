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
      PermissionCodes.categoryView,
      PermissionCodes.categoryCreate,
      PermissionCodes.invitationView,
      PermissionCodes.invitationCreate,
      PermissionCodes.tableCreate,
    ];