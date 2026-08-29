import '../api/api_client.dart';
import '../api/api_config.dart';

/// Utilisateur (`UserResponse`) — admin.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.active,
    required this.roles,
    this.organizationId,
    this.phone,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool active;
  final List<String> roles;
  final int? organizationId;
  final String? phone;

  String get displayName => '$firstName $lastName';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: (json['id'] as num).toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        organizationId: (json['organizationId'] as num?)?.toInt(),
        phone: json['phone'] as String?,
      );
}

/// Rôle (`RoleResponse`).
class AdminRole {
  const AdminRole({
    required this.id,
    required this.code,
    this.description,
    required this.active,
    this.permissionCodes = const [],
  });

  final int id;
  final String code;
  final String? description;
  final bool active;
  final List<String> permissionCodes;

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        active: json['active'] as bool? ?? true,
        permissionCodes: (json['permissionCodes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Permission (`PermissionResponse`).
class AdminPermission {
  const AdminPermission({required this.id, required this.code, this.libelle, this.categorie});

  final int id;
  final String code;
  final String? libelle;
  final String? categorie;

  factory AdminPermission.fromJson(Map<String, dynamic> json) => AdminPermission(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        libelle: json['libelle'] as String?,
        categorie: json['categorie'] as String?,
      );
}

/// Organisation (`OrganizationResponse`).
class AdminOrganization {
  const AdminOrganization({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.active,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final bool active;

  factory AdminOrganization.fromJson(Map<String, dynamic> json) => AdminOrganization(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        active: json['active'] as bool? ?? true,
      );
}

/// Client API du module admin (users/roles/permissions/orgs).
class AdminApi {
  AdminApi({required this.api});

  final ApiClient api;

  Future<List<AdminUser>> listUsers({int page = 0, int size = 25}) async {
    final raw = await api.getList(
      ApiConfig.usersPath,
      queryParameters: {'page': page, 'size': size},
    );
    return raw.whereType<Map<String, dynamic>>().map((e) => AdminUser.fromJson(e)).toList();
  }

  Future<List<AdminRole>> listRoles() async {
    final raw = await api.getList(ApiConfig.rolesPath);
    return raw.whereType<Map<String, dynamic>>().map((e) => AdminRole.fromJson(e)).toList();
  }

  Future<List<AdminPermission>> listPermissions() async {
    final raw = await api.getList(ApiConfig.permissionsPath);
    return raw.whereType<Map<String, dynamic>>().map((e) => AdminPermission.fromJson(e)).toList();
  }

  Future<List<AdminOrganization>> listOrganizations() async {
    final raw = await api.getList(ApiConfig.organizationsPath);
    return raw.whereType<Map<String, dynamic>>().map((e) => AdminOrganization.fromJson(e)).toList();
  }
}