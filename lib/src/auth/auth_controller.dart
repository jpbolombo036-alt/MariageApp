import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import 'auth_models.dart';
import 'auth_providers.dart';
import 'permission_roles.dart';
import 'secure_token_store.dart';

/// État global d'authentification exposé aux widgets.
class AuthState {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.restored = false,
    this.permissions = const [],
  });

  final AuthUser? user;
  final bool isAuthenticated;
  final bool restored;
  final List<String> permissions;

  /// Vérifie une permission (ex. `WEDDING_UPDATE`). Le backend reste l'autorité.
  bool hasPermission(String code) => permissions.any((p) => p == code);

  AuthState copyWith({
    AuthUser? user,
    bool? isAuthenticated,
    bool? restored,
    List<String>? permissions,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      restored: restored ?? this.restored,
      permissions: permissions ?? this.permissions,
    );
  }

  static const empty = AuthState();
}

/// Contrôleur d'authentification (Notifier Riverpod, sans génération de code).
///
/// La restauration de session est déclenchée par [kickRestore] (idempotent),
/// qui marque l'état « restauré » de façon synchrone puis recharge le token en
/// arrière-plan. Cela évite toute lecture du stockage sécurisé pendant le
/// build d'un Consumer (dépendance circulaire).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.empty;

  bool _kickStarted = false;

  ApiClient get _api => ref.watch(apiClientProvider);
  SecureTokenStore get _store => ref.watch(secureTokenStoreProvider);

  /// Marque la session restaurée et recharge le token en arrière-plan.
  void kickRestore() {
    if (_kickStarted) return;
    _kickStarted = true;
    // Décale la modification hors du build (interdit par Riverpod).
    Future<void>(() async {
      state = state.copyWith(restored: true);
      await _restoreFromStore();
    });
  }

  Future<void> _restoreFromStore() async {
    try {
      final access = await _store.readAccessToken();
      if (access == null || access.isEmpty) return;
      _api.setAccessToken(access);
      await _fetchMe();
    } catch (_) {
      state = state.copyWith(isAuthenticated: false);
    }
  }

  /// Connexion via `POST /auth/login`.
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final json = await _api.postJson(
        ApiConfig.authLogin,
        {'email': email, 'password': password},
      );
      return _applyLogin(json);
    } catch (_) {
      return AuthResult.failure('Erreur réseau : connexion impossible');
    }
  }

  /// Inscription via `POST /auth/register` (crée aussi l'organisation).
  Future<AuthResult> register(RegisterRequest request) async {
    try {
      await _api.postJson(ApiConfig.authRegister, request.toJson());
      final json = await _api.postJson(
        ApiConfig.authLogin,
        {'email': request.email, 'password': request.password},
      );
      return _applyLogin(json);
    } catch (_) {
      return AuthResult.failure('Erreur lors de l’inscription');
    }
  }

  /// Déconnexion : appelle `/auth/logout` puis efface le stockage local.
  Future<void> logout() async {
    try {
      await _api.postNoContent(ApiConfig.authLogout);
    } catch (_) {
      // On déconnecte localement même si le serveur est injoignable.
    }
    await _store.clear();
    state = AuthState.empty;
  }

  AuthResult _applyLogin(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return AuthResult.failure('Identifiants invalides');
    }
    final login = LoginResponse.fromJson(json);
    _api.setAccessToken(login.accessToken);
    _store.save(
      accessToken: login.accessToken,
      refreshToken: login.refreshToken,
      expiresIn: login.expiresIn,
    );
    state = AuthState(
      user: login.user,
      isAuthenticated: true,
      restored: true,
      permissions: permissionsForRoles(login.user.roles),
    );
    return AuthResult.success();
  }

  Future<bool> _fetchMe() async {
    try {
      final json = await _api.getJson(ApiConfig.authMe);
      if (json.containsKey('error')) {
        state = state.copyWith(isAuthenticated: false);
        return false;
      }
      final user = AuthUser.fromJson(json);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        permissions: permissionsForRoles(user.roles),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Résultat d'une opération d'authentification.
class AuthResult {
  factory AuthResult.failure(String error) => AuthResult._(
        isSuccess: false,
        error: error,
      );

  factory AuthResult.success() => AuthResult._(isSuccess: true);

  AuthResult._({required this.isSuccess, this.error});

  final bool isSuccess;
  final String? error;
}