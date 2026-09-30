/// Configuration réseau de l'application EventiaEasy.
///
/// API EventiaEasy. Surcharge possible au build avec
/// `--dart-define=API_BASE_URL=https://…`.
class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _productionBaseUrl =
      'https://mariageplus-production-a657.up.railway.app';

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return _productionBaseUrl;
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

  /// Réglages plateforme (lecture : tout utilisateur authentifié ;
  /// écriture : SUPER_ADMIN uniquement).
  static const String adminWhatsappSettingsPath = '/api/admin/settings/whatsapp';
}