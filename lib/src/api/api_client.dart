import 'dart:convert';

import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../auth/secure_token_store.dart';
import 'api_config.dart';

/// Client HTTP central (Dio) pour MariagePlus.
///
/// - Injecte automatiquement `Authorization: Bearer <accessToken>`.
/// - Sur `401` d'une requête authentifiée (hors `/auth/refresh`) : tente un
///   refresh via `POST /auth/refresh` (body brut = refresh token) puis rejoue
///   **une seule fois** la requête initiale. Échec → `onSessionExpired`.
///
/// La base URL est configurée selon la plateforme (voir [ApiConfig]).
class ApiClient {
  ApiClient({
    required this.tokenStore,
    this.onSessionExpired,
  }) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequestInterceptor,
        onError: _onErrorInterceptor,
      ),
    );
    // Recharge le Bearer au démarrage s'il existe déjà.
    _restoreBearerFromStore();
  }

  final SecureTokenStore tokenStore;
  final Future<void> Function()? onSessionExpired;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  bool _refreshing = false;

  Dio get dio => _dio;

  /// Met à jour le Bearer global (appelé après login/refresh).
  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> _restoreBearerFromStore() async {
    final token = await tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) setAccessToken(token);
  }

  Future<Object?> _onRequestInterceptor(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
    return null;
  }

  Future<Object?> _onErrorInterceptor(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    final bool isUnauthorized = e.response?.statusCode == 401;
    final bool isRefreshPath = e.requestOptions.path == ApiConfig.authRefresh;

    if (isUnauthorized && !isRefreshPath && !_refreshing) {
      _refreshing = true;
      try {
        final refreshToken = await tokenStore.readRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshed = await _dio.post<dynamic>(
            ApiConfig.authRefresh,
            data: refreshToken,
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          final json = _decodeMap(refreshed.data);
          if (json != null) {
            final login = LoginResponse.fromJson(json);
            await tokenStore.save(
              accessToken: login.accessToken,
              refreshToken: login.refreshToken,
              expiresIn: login.expiresIn,
            );
            setAccessToken(login.accessToken);
            // Rejoue la requête initiale UNE fois.
            final response = await _dio.request<dynamic>(
              e.requestOptions.path,
              data: e.requestOptions.data,
              queryParameters: e.requestOptions.queryParameters,
              options: Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              ),
            );
            handler.resolve(response);
            return null;
          }
        }
      } catch (_) {
        // Échec du refresh → on laisse tomber (déconnexion).
      } finally {
        _refreshing = false;
      }
      await tokenStore.clear();
      if (onSessionExpired != null) await onSessionExpired!();
    }

    handler.next(e);
    return null;
  }

  Map<String, dynamic>? _decodeMap(dynamic data) {
    if (data is Map) return data as Map<String, dynamic>;
    if (data is String) {
      if (data.isEmpty) return null;
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// GET JSON avec gestion automatique du Bearer.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return _decodeMap(response.data) ?? <String, dynamic>{};
  }

  /// POST JSON avec gestion automatique du Bearer.
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic>? data,
  ) async {
    final response = await _dio.post<dynamic>(path, data: data);
    return _decodeMap(response.data) ?? <String, dynamic>{};
  }

  /// PUT JSON avec gestion automatique du Bearer.
  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic>? data,
  ) async {
    final response = await _dio.put<dynamic>(path, data: data);
    return _decodeMap(response.data) ?? <String, dynamic>{};
  }

  /// PATCH JSON avec gestion automatique du Bearer.
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic>? data,
  ) async {
    final response = await _dio.patch<dynamic>(path, data: data);
    return _decodeMap(response.data) ?? <String, dynamic>{};
  }

  /// DELETE renvoyant 204 / 200 (suppression logique).
  Future<void> deleteRequest(String path) async {
    await _dio.delete<dynamic>(path);
  }

  /// GET retournant une liste JSON (ex. `PageResponse.content`).
  ///
  /// [contentKey] désigne le champ de la liste dans la réponse paginée
  /// (défaut `content` pour `PageResponse`).
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    String contentKey = 'content',
  }) async {
    final json = await getJson(path, queryParameters: queryParameters);
    return json[contentKey] as List<dynamic>? ?? const [];
  }

  /// POST renvoyant 204 / 200 sans corps (logout).
  Future<void> postNoContent(String path) async {
    await _dio.post<dynamic>(path);
  }
}