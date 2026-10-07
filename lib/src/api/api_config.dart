import 'package:flutter/foundation.dart';

/// Configuration réseau de l'application EventiaEasy.
///
/// L'URL de base est résolue dans cet ordre de priorité :
///
/// 1. `--dart-define=API_BASE_URL=https://…` → priorité absolue
/// 2. `--dart-define=API_ENV=local|prod` → preset nommé
/// 3. Build **release** (`flutter build apk`) → [_productionBaseUrl]
/// 4. Build **debug** (`flutter run`) → backend local, choisi automatiquement
///    selon la plateforme :
///    - Android (émulateur) : `http://10.0.2.2:8000`
///    - iOS / desktop       : `http://localhost:8000`
///
/// Résultat : `flutter run` cible le backend local et
/// `flutter build apk --release` la production, **sans modifier le code**.
class ApiConfig {
  ApiConfig._();

  /// Surcharge explicite de l'URL (`--dart-define=API_BASE_URL=…`).
  static const String _defineBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Preset d'environnement (`--dart-define=API_ENV=local|prod`).
  static const String _defineEnv = String.fromEnvironment('API_ENV');

  /// Backend local pour l'émulateur Android (`10.0.2.2` = `localhost` de l'hôte).
  static const String localAndroidBaseUrl = 'http://10.0.2.2:8000';

  /// Backend local pour iOS / desktop / web.
  static const String localBaseUrl = 'http://localhost:8000';

  /// Backend de production (Railway).
  static const String productionBaseUrl =
      'https://mariageplus-production-a657.up.railway.app';

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    if (_defineBaseUrl.isNotEmpty) return _normalize(_defineBaseUrl);
    if (_defineEnv.isNotEmpty) return _normalize(_fromEnvName(_defineEnv));
    return productionBaseUrl;
  }

  /// Backend correspondant à la plateforme courante.
  static String get defaultLocalBaseUrl =>
      defaultTargetPlatform == TargetPlatform.android
          ? localAndroidBaseUrl
          : localBaseUrl;

  /// Convertit un nom d'environnement en URL. Toute valeur inconnue retombe
  /// sur le backend local (plus sûr en développement).
  static String _fromEnvName(String env) {
    switch (env.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return productionBaseUrl;
      case 'local':
      case 'dev':
      case 'debug':
      case 'staging':
      case 'test':
        return defaultLocalBaseUrl;
      default:
        return defaultLocalBaseUrl;
    }
  }

  /// Supprime les slashs finaux pour éviter les `//` dans les requêtes.
  static String _normalize(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
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