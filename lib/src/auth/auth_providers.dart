import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_controller.dart';
import 'secure_token_store.dart';

/// Stockage sécurisé des tokens (singleton partagé).
final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(),
);

/// Client HTTP central (Bearer + refresh-401).
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(secureTokenStoreProvider));
});

/// Contrôle d'authentification (session, user, permissions).
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);