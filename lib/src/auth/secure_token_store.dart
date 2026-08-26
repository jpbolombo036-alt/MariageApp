import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé des tokens (Keychain/Keystore).
///
/// Ne stocke **jamais** le mot de passe. Les tokens sont persistés dans le
/// stockage sécurisé de la plateforme (Android Keystore, iOS Keychain).
class SecureTokenStore {
  SecureTokenStore();

  static const String _accessKey = 'mariageplus.access_token';
  static const String _refreshKey = 'mariageplus.refresh_token';
  static const String _expiresKey = 'mariageplus.expires_in';

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Enregistre la session (access + refresh + durée) de manière atomique.
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _expiresKey, value: expiresIn.toString());
  }

  /// Access token courant, ou null si absent.
  Future<String?> readAccessToken() async => await _storage.read(key: _accessKey);

  /// Refresh token courant, ou null si absent.
  Future<String?> readRefreshToken() async => await _storage.read(key: _refreshKey);

  /// Durée de validité (secondes) stockée, ou 0.
  Future<int> readExpiresIn() async {
    final raw = await _storage.read(key: _expiresKey);
    return raw == null ? 0 : int.parse(raw);
  }

  /// Efface tous les tokens (logout / session expirée).
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
  }

  /// True si un access token est présent en stockage.
  Future<bool> hasSession() async => await _storage.containsKey(key: _accessKey);
}