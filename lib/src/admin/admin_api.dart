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

  /// État de l'envoi WhatsApp (`GET /api/admin/settings/whatsapp`).
  /// Interrupteur global : false = les points d'entrée WhatsApp sont masqués.
  Future<bool> isWhatsappSendingEnabled() async {
    final json = await api.getJson(ApiConfig.adminWhatsappSettingsPath);
    return json['whatsappSendingEnabled'] as bool? ?? true;
  }

  /// Activer / désactiver l'envoi WhatsApp (SUPER_ADMIN — 403 sinon).
  Future<bool> updateWhatsappSendingEnabled(bool enabled) async {
    final json = await api.putJson(
        ApiConfig.adminWhatsappSettingsPath, {'enabled': enabled});
    return json['whatsappSendingEnabled'] as bool? ?? enabled;
  }

  /// Ajout d'un membre à une organisation (rôle ORGANISATEUR).
  Future<void> addOrganizationMember(int organizationId, AdminAddMemberRequest request) async {
    await api.postJson(
      '${ApiConfig.organizationsPath}/$organizationId/members',
      request.toJson(),
    );
  }

  Future<List<OrgMember>> listMembers(int organizationId) async {
    final raw = await api.getList(
      '${ApiConfig.organizationsPath}/$organizationId/members',
    );
    return raw.whereType<Map<String, dynamic>>().map(OrgMember.fromJson).toList();
  }

  Future<void> updateMemberWedding(
    int organizationId,
    int memberId,
    int weddingId,
  ) async {
    await api.putJson(
      '${ApiConfig.organizationsPath}/$organizationId/members/$memberId',
      {'weddingId': weddingId},
    );
  }

  Future<void> removeMember(int organizationId, int memberId) async {
    await api.deleteRequest(
      '${ApiConfig.organizationsPath}/$organizationId/members/$memberId',
    );
  }

  Future<void> toggleUserActive(int userId) async {
    await api.patchJson('${ApiConfig.usersPath}/$userId/toggle-active', {});
  }

  Future<void> toggleOrganizationActive(int organizationId) async {
    await api.patchJson(
      '${ApiConfig.organizationsPath}/$organizationId/toggle-active',
      {},
    );
  }

  Future<void> deleteRole(int roleId) async {
    await api.deleteRequest('${ApiConfig.rolesPath}/$roleId');
  }

  Future<AdminRole> createRole(AdminCreateRoleRequest request) async {
    final json = await api.postJson(ApiConfig.rolesPath, request.toJson());
    return AdminRole.fromJson(json);
  }

  Future<AdminRole> updateRole(int roleId, AdminUpdateRoleRequest request) async {
    final json = await api.putJson('${ApiConfig.rolesPath}/$roleId', request.toJson());
    return AdminRole.fromJson(json);
  }

  Future<void> deleteUser(int userId) async {
    await api.deleteRequest('${ApiConfig.usersPath}/$userId');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
      return api.putJson('${ApiConfig.usersPath}/me', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
  }

  Future<void> uploadAvatar(List<int> bytes, String contentType) async {
    await api.postMultipart('${ApiConfig.usersPath}/me/avatar', bytes: bytes, contentType: contentType);
  }

  Future<void> deleteAvatar() async {
    await api.deleteRequest('${ApiConfig.usersPath}/me/avatar');
  }

  Future<bool> isEventCreationEnabled() async {
    final json = await api.getJson('/api/platform/event-creation-enabled');
    return json['enabled'] as bool? ?? true;
  }

  Future<bool> getAdminEventCreation() async {
    final json = await api.getJson('/api/admin/settings/event-creation');
    return json['eventCreationEnabled'] as bool? ?? true;
  }

  Future<bool> updateAdminEventCreation(bool enabled) async {
    final json = await api.putJson(
      '/api/admin/settings/event-creation',
      {'enabled': enabled},
    );
    return json['eventCreationEnabled'] as bool? ?? enabled;
  }

  Future<Map<String, dynamic>> organizationSettings(int organizationId) async {
    return api.getJson('/api/admin/organizations/$organizationId/settings');
  }

  Future<Map<String, dynamic>> updateOrganizationSettings(
    int organizationId, {
    Object? eventCreationEnabled,
    Object? whatsappEnabled,
  }) async {
    return api.putJson(
      '/api/admin/organizations/$organizationId/settings',
      {
        if (eventCreationEnabled != null) 'eventCreationEnabled': eventCreationEnabled,
        if (whatsappEnabled != null) 'whatsappEnabled': whatsappEnabled,
      },
    );
  }

  Future<AdminUser> createUser(AdminCreateUserRequest request) async {
    final json = await api.postJson(ApiConfig.usersPath, request.toJson());
    return AdminUser.fromJson(json);
  }

  Future<AdminUser> updateUser(int userId, AdminUpdateUserRequest request) async {
    final json = await api.putJson('${ApiConfig.usersPath}/$userId', request.toJson());
    return AdminUser.fromJson(json);
  }

  Future<void> assignRoleToUser(int userId, AdminAssignRoleRequest request) async {
    await api.postJson('${ApiConfig.usersPath}/$userId/roles', request.toJson());
  }

  Future<void> removeRoleFromUser(int userId, int roleId) async {
    await api.deleteRequest('${ApiConfig.usersPath}/$userId/roles/$roleId');
  }

  Future<AdminOrganization> createOrganization(AdminCreateOrganizationRequest request) async {
    final json = await api.postJson(ApiConfig.organizationsPath, request.toJson());
    return AdminOrganization.fromJson(json);
  }

  Future<AdminOrganization> updateOrganization(int organizationId, AdminUpdateOrganizationRequest request) async {
    final json = await api.putJson('${ApiConfig.organizationsPath}/$organizationId', request.toJson());
    return AdminOrganization.fromJson(json);
  }

  Future<void> deleteOrganization(int organizationId) async {
    await api.deleteRequest('${ApiConfig.organizationsPath}/$organizationId');
  }
}

/// Membre d'une organisation.
class OrgMember {
  const OrgMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roleCode,
    this.weddingId,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String roleCode;
  final int? weddingId;

  String get displayName => '$firstName $lastName';

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
        id: (json['id'] as num).toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        roleCode: json['roleCode'] as String? ?? '',
        weddingId: (json['weddingId'] as num?)?.toInt(),
      );
}

/// Requête d'ajout d'un membre (`AddOrganizationMemberRequest` backend).
class AdminAddMemberRequest {
  AdminAddMemberRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.password,
    required this.roleCode,
    this.weddingId,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String password;
  final String roleCode;
  final int? weddingId;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'password': password,
        'roleCode': roleCode,
        if (weddingId != null) 'weddingId': weddingId,
      };
}

class AdminCreateUserRequest {
  AdminCreateUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.password,
    this.organizationId,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String password;
  final int? organizationId;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'password': password,
        if (organizationId != null) 'organizationId': organizationId,
      };
}

class AdminUpdateUserRequest {
  AdminUpdateUserRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.active,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final bool? active;

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (active != null) 'active': active,
      };
}

class AdminAssignRoleRequest {
  AdminAssignRoleRequest({required this.roleCode});

  final String roleCode;

  Map<String, dynamic> toJson() => {'roleCode': roleCode};
}

class AdminCreateOrganizationRequest {
  AdminCreateOrganizationRequest({
    required this.name,
    this.email,
    this.phone,
    this.address,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? address;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}

class AdminUpdateOrganizationRequest {
  AdminUpdateOrganizationRequest({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.active,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final bool? active;

  Map<String, dynamic> toJson() => {
        if (name != null && name!.isNotEmpty) 'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (active != null) 'active': active,
      };
}

class AdminCreateRoleRequest {
  AdminCreateRoleRequest({
    required this.code,
    this.description,
    this.active = true,
  });

  final String code;
  final String? description;
  final bool active;

  Map<String, dynamic> toJson() => {
        'code': code,
        if (description != null && description!.isNotEmpty) 'description': description,
        'active': active,
      };
}

class AdminUpdateRoleRequest {
  AdminUpdateRoleRequest({
    required this.code,
    this.description,
    this.active,
  });

  final String code;
  final String? description;
  final bool? active;

  Map<String, dynamic> toJson() => {
        'code': code,
        if (description != null) 'description': description,
        if (active != null) 'active': active,
      };
}