/// Configuration réseau de l'application MariagePlus.
///
/// Le backend Spring Boot écoute sur `SERVER_PORT` (8000 en local).
/// - **Production (Railway)** → `https://mariageplus-production.up.railway.app` (défaut)
/// - Émulateur Android (dev) → `http://10.0.2.2:8000` via `API_BASE_URL`
/// - Desktop / iOS simulator (dev) → `http://localhost:8000` via `API_BASE_URL`
///
/// L'URL par défaut pointe vers le backend de production. Pour un environnement
/// local ou un autre déploiement, surchargez-la à la compilation :
/// `flutter run/build --dart-define=API_BASE_URL=https://...` (ou http://10.0.2.2:8000).
class ApiConfig {
  ApiConfig._();

  /// URL de production (Railway) utilisée par défaut.
  static const String _defaultBaseUrl =
      'https://mariageplus-production.up.railway.app';

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    final fromEnv = _envBaseUrl.trim();
    final raw = fromEnv.isNotEmpty ? fromEnv : _defaultBaseUrl;
    return raw.endsWith('/')
        ? raw.substring(0, raw.length - 1)
        : raw;
  }

  /// Chemins relatifs de l'API.
  ///
  /// NB : les routes d'authentification sont **sans** préfixe `/api`
  /// (controller `@RequestMapping("/auth")`), contrairement au reste
  /// (`/api/weddings`, `/api/guests`, ...).
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  /// Mariages / événements.
  static const String weddingsPath = '/api/weddings';

  /// Profil utilisateur (changement de mot de passe).
  static const String usersMePassword = '/api/users/me/password';

  /// Événements d'un mariage (sous-ressource de weddings).
  static String weddingEventsPath(int weddingId) =>
      '$weddingsPath/$weddingId/events';

  /// Accès public (RSVP) et check-in.
  static const String publicInvitationsPath = '/api/public/invitations';
  static const String checkinsPath = '/api/checkins';

  /// Réponses RSVP d'un mariage (lecture, rôle GESTIONNAIRE_INVITES).
  static String weddingRsvpsPath(int weddingId) =>
      '$weddingsPath/$weddingId/rsvps';

  /// Administration (SUPER_ADMIN).
  static const String usersPath = '/api/users';
  static const String rolesPath = '/api/roles';
  static const String permissionsPath = '/api/permissions';
  static const String organizationsPath = '/api/organizations';
}