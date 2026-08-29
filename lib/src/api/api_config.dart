import 'dart:io';

/// Configuration réseau de l'application MariagePlus.
///
/// Le backend Spring Boot écoute sur `SERVER_PORT` (8000 en local).
/// - Émulateur Android → `http://10.0.2.2:8000` (hôte local vu depuis l'émulateur)
/// - Desktop / iOS simulator / navigateur → `http://localhost:8000`
///
/// À surcharger en production via une URL fournie par l'environnement
/// (ex. `String.fromEnvironment('API_BASE_URL')`) sans exposer de secret.
class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  /// Chemins relatifs de l'API.
  ///
  /// NB : les routes d'authentification sont **sans** préfixe `/api`
  /// (controller `@RequestMapping("/auth")`), contrairement au reste
  /// (`/api/events`, `/api/guests`, ...).
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  /// Mariages / événements.
  static const String eventsPath = '/api/events';

  /// Accès public (RSVP) et check-in.
  static const String publicInvitationsPath = '/api/public/invitations';
  static const String checkinsPath = '/api/checkins';

  /// Administration (SUPER_ADMIN).
  static const String usersPath = '/api/users';
  static const String rolesPath = '/api/roles';
  static const String permissionsPath = '/api/permissions';
  static const String organizationsPath = '/api/organizations';
}