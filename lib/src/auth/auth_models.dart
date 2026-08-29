/// Modèles d'authentification (DTO réels du backend Spring Boot `com.mariageplus`).
///
/// Ces classes correspondent aux réponses JSON :
/// - `LoginResponse` (accessToken, refreshToken, expiresIn, tokenType, user)
/// - `UserResponse` renvoyé par l'API (avec roles + organizationId).
library;

class LoginRequest {
  LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.organizationName,
    this.phone,
    this.organizationEmail,
    this.organizationPhone,
    this.organizationAddress,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String organizationName;
  final String? phone;
  final String? organizationEmail;
  final String? organizationPhone;
  final String? organizationAddress;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'organizationName': organizationName,
        if (phone != null) 'phone': phone,
        if (organizationEmail != null) 'organizationEmail': organizationEmail,
        if (organizationPhone != null) 'organizationPhone': organizationPhone,
        if (organizationAddress != null) 'organizationAddress': organizationAddress,
      };
}

/// Utilisateur connecté (sous-champ `user` de `LoginResponse` et `UserResponse`).
class AuthUser {
  AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.active,
    required this.roles,
    this.organizationId,
    this.phone,
    this.emailVerified,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool active;
  final List<String> roles;
  final int? organizationId;
  final String? phone;
  final bool? emailVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        active: json['active'] as bool? ?? false,
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        organizationId: (json['organizationId'] as num?)?.toInt(),
        phone: json['phone'] as String?,
        emailVerified: json['emailVerified'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'active': active,
        'roles': roles,
        'organizationId': organizationId,
        if (phone != null) 'phone': phone,
        if (emailVerified != null) 'emailVerified': emailVerified,
      };
}

/// Réponse de connexion / inscription / refresh.
class LoginResponse {
  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String? ?? '',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Les permissions renvoyées par le backend (_affichage conditionnel_).
///
/// Rappel : le frontend masque les actions interdites via la présence de ces
/// permissions dans le profil de l'utilisateur, mais le **backend reste
/// l'autorité de sécurité** (RBAC + isolation par organisation).
class PermissionCodes {
  PermissionCodes._();

  static const String weddingView = 'WEDDING_VIEW';
  static const String weddingCreate = 'WEDDING_CREATE';
  static const String weddingUpdate = 'WEDDING_UPDATE';
  static const String weddingDelete = 'WEDDING_DELETE';
  static const String weddingPublish = 'WEDDING_PUBLISH';
  static const String weddingArchive = 'WEDDING_ARCHIVE';
  static const String dashboardView = 'DASHBOARD_VIEW';
  static const String guestView = 'GUEST_VIEW';
  static const String guestCreate = 'GUEST_CREATE';
  static const String guestUpdate = 'GUEST_UPDATE';
  static const String guestDelete = 'GUEST_DELETE';
  static const String categoryView = 'CATEGORY_VIEW';
  static const String categoryCreate = 'CATEGORY_CREATE';
  static const String invitationView = 'INVITATION_VIEW';
  static const String invitationCreate = 'INVITATION_CREATE';
  static const String checkinCreate = 'CHECKIN_CREATE';
  static const String tableCreate = 'TABLE_CREATE';

  // --- Codes du modèle unifié "Event" (mêmes rôles seedés backend) ---
  static const String eventView = 'EVENT_VIEW';
  static const String eventCreate = 'EVENT_CREATE';
  static const String eventUpdate = 'EVENT_UPDATE';
  static const String eventDelete = 'EVENT_DELETE';
  static const String organizationManageMembers = 'ORGANIZATION_MANAGE_MEMBERS';
}