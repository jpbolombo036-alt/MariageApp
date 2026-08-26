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

/// Membre d'une organisation (`OrganizationMemberResponse`).
class AdminOrganizationMember {
  const AdminOrganizationMember({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.roleCode,
    required this.active,
  });

  final int id;
  final int? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String roleCode;
  final bool active;

  factory AdminOrganizationMember.fromJson(Map<String, dynamic> json) =>
      AdminOrganizationMember(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['userId'] as num?)?.toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        roleCode: json['roleCode'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );
}

/// Requête utilisateur (`UserRequest`).
class AdminUserRequest {
  AdminUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.password,
    this.roleCodes = const [],
    this.organizationId,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? password;
  final List<String> roleCodes;
  final int? organizationId;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (password != null) 'password': password,
        'roleCodes': roleCodes,
        if (organizationId != null) 'organizationId': organizationId,
      };
}

/// Requête d'organisation (`OrganizationRequest`).
class AdminOrganizationRequest {
  AdminOrganizationRequest({required this.name, this.email, this.phone, this.address, this.active});

  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final bool? active;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (active != null) 'active': active,
      };
}

/// Requête d'ajout de membre (`OrganizationMemberRequest`).
class AdminAddMemberRequest {
  AdminAddMemberRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.password,
    required this.roleCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String password;
  final String roleCode;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
        'roleCode': roleCode,
      };
}

/// Requête de rôle (`RoleRequest`).
class AdminRoleRequest {
  AdminRoleRequest({required this.code, this.description, this.active, this.permissionCodes = const []});

  final String code;
  final String? description;
  final bool? active;
  final List<String> permissionCodes;

  Map<String, dynamic> toJson() => {
        'code': code,
        if (description != null) 'description': description,
        if (active != null) 'active': active,
        'permissionCodes': permissionCodes,
      };
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

  // --- Utilisateurs (SUPER_ADMIN) ---
  Future<AdminUser> createUser(AdminUserRequest request) async {
    final json = await api.postJson(ApiConfig.usersPath, request.toJson());
    return AdminUser.fromJson(json);
  }

  Future<AdminUser> updateUser(int id, AdminUserRequest request) async {
    final json = await api.putJson('${ApiConfig.usersPath}/$id', request.toJson());
    return AdminUser.fromJson(json);
  }

  Future<AdminUser> toggleUserActive(int id) async {
    final json = await api.patchJson('${ApiConfig.usersPath}/$id/toggle-active', null);
    return AdminUser.fromJson(json);
  }

  Future<void> deleteUser(int id) async {
    await api.deleteRequest('${ApiConfig.usersPath}/$id');
  }

  // --- Rôles (SUPER_ADMIN) ---
  Future<AdminRole> createRole(AdminRoleRequest request) async {
    final json = await api.postJson(ApiConfig.rolesPath, request.toJson());
    return AdminRole.fromJson(json);
  }

  Future<AdminRole> updateRole(int id, AdminRoleRequest request) async {
    final json = await api.putJson('${ApiConfig.rolesPath}/$id', request.toJson());
    return AdminRole.fromJson(json);
  }

  Future<AdminRole> replaceRolePermissions(int id, List<String> permissionCodes) async {
    final response = await api.dio.put<dynamic>(
      '${ApiConfig.rolesPath}/$id/permissions',
      data: permissionCodes,
    );
    return AdminRole.fromJson(
      (response.data as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Future<void> deleteRole(int id) async {
    await api.deleteRequest('${ApiConfig.rolesPath}/$id');
  }

  // --- Organisations (SUPER_ADMIN) + membres ---
  Future<AdminOrganization> createOrganization(AdminOrganizationRequest request) async {
    final json = await api.postJson(ApiConfig.organizationsPath, request.toJson());
    return AdminOrganization.fromJson(json);
  }

  Future<AdminOrganization> updateOrganization(int id, AdminOrganizationRequest request) async {
    final json = await api.putJson('${ApiConfig.organizationsPath}/$id', request.toJson());
    return AdminOrganization.fromJson(json);
  }

  Future<AdminOrganization> toggleOrganizationActive(int id) async {
    final json = await api.patchJson('${ApiConfig.organizationsPath}/$id/toggle-active', null);
    return AdminOrganization.fromJson(json);
  }

  Future<List<AdminOrganizationMember>> listOrganizationMembers(int organizationId) async {
    final raw = await api.getList('${ApiConfig.organizationsPath}/$organizationId/members');
    return raw.whereType<Map<String, dynamic>>().map((e) => AdminOrganizationMember.fromJson(e)).toList();
  }

  Future<AdminOrganizationMember> addOrganizationMember(
    int organizationId,
    AdminAddMemberRequest request,
  ) async {
    final json = await api.postJson(
      '${ApiConfig.organizationsPath}/$organizationId/members',
      request.toJson(),
    );
    return AdminOrganizationMember.fromJson(json);
  }
}