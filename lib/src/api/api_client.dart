import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../auth/secure_token_store.dart';
import 'api_config.dart';

/// Client HTTP central (Dio) pour EventiaEasy.
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
  Future<bool>? _refreshInFlight;

  Dio get dio => _dio;

  /// Met à jour le Bearer global (appelé après login/refresh).
  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Retire le Bearer mémoire (logout ou session révoquée).
  void clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Changement du mot de passe de l'utilisateur connecté
  /// (`PUT /api/users/me/password`).
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await putJson(
      '${ApiConfig.usersPath}/me/password',
      {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
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
    } else {
      // Sinon le Bearer révoqué au logout reste collé et bloque le prochain login.
      options.headers.remove('Authorization');
    }
    handler.next(options);
    return null;
  }

  Future<Object?> _onErrorInterceptor(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    final bool isUnauthorized = e.response?.statusCode == 401;
    final path = e.requestOptions.path;
    final bool isRefreshPath = path == ApiConfig.authRefresh;
    final bool isCredentialAttempt =
        path == ApiConfig.authLogin || path == ApiConfig.authRegister;
    final bool alreadyRetried = e.requestOptions.extra['authRetried'] == true;

    if (isUnauthorized && !isRefreshPath && !isCredentialAttempt && !alreadyRetried) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        try {
          e.requestOptions.extra['authRetried'] = true;
          final response = await _dio.fetch<dynamic>(e.requestOptions);
          handler.resolve(response);
          return null;
        } catch (err) {
          if (err is DioException && err.response?.statusCode == 401) {
            await _expireSession();
          }
          if (err is DioException) {
            handler.next(err);
          } else {
            handler.next(e);
          }
          return null;
        }
      }
      await _expireSession();
    }

    handler.next(e);
    return null;
  }

  /// Un seul refresh pour toutes les requêtes 401 concurrentes.
  Future<bool> _refreshSession() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = await tokenStore.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      final refreshed = await _dio.post<dynamic>(
        ApiConfig.authRefresh,
        data: refreshToken,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          extra: const {'authRetried': true},
        ),
      );
      final json = _decodeMap(refreshed.data);
      if (json == null) return false;
      final login = LoginResponse.fromJson(json);
      await tokenStore.save(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
        expiresIn: login.expiresIn,
      );
      setAccessToken(login.accessToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _expireSession() async {
    await tokenStore.clear();
    clearAccessToken();
    if (onSessionExpired != null) await onSessionExpired!();
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

  /// GET retournant une liste JSON.
  ///
  /// Accepte un tableau brut ou une page Spring (`content`).
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    String contentKey = 'content',
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    final data = response.data;
    if (data is List) return data;
    final json = _decodeMap(data) ?? <String, dynamic>{};
    final content = json[contentKey];
    if (content is List) return content;
    return const [];
  }

  /// Page Spring (`content`, `last`, `number`, `totalElements`).
  Future<ApiPage> getPage(
    String path, {
    Map<String, dynamic>? queryParameters,
    String contentKey = 'content',
  }) async {
    final json = await getJson(path, queryParameters: queryParameters);
    final content = json[contentKey] as List<dynamic>? ?? const [];
    final hasPaging = json.containsKey('last') || json.containsKey('totalPages');
    final lastFlag = json['last'] as bool? ?? true;
    return ApiPage(
      content: content,
      last: !hasPaging || lastFlag || content.isEmpty,
      number: (json['number'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? content.length,
    );
  }

  /// Enchaîne les pages Spring jusqu'à `last` (plafond de sûreté).
  Future<List<Map<String, dynamic>>> getAllMaps(
    String path, {
    int size = 25,
    Map<String, dynamic>? queryParameters,
    int maxPages = 40,
  }) async {
    final all = <Map<String, dynamic>>[];
    for (var page = 0; page < maxPages; page++) {
      final slice = await getPage(
        path,
        queryParameters: {
          ...?queryParameters,
          'page': page,
          'size': size,
        },
      );
      all.addAll(slice.content.whereType<Map<String, dynamic>>());
      if (slice.last) break;
    }
    return all;
  }

  /// POST renvoyant 204 / 200 sans corps (logout).
  Future<void> postNoContent(String path) async {
    await _dio.post<dynamic>(path);
  }

  /// GET JSON qui peut répondre 204 (aucun contenu).
  Future<Map<String, dynamic>?> getJsonOrNull(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    if (response.statusCode == 204 || response.data == null) return null;
    final map = _decodeMap(response.data);
    if (map == null || map.isEmpty) return null;
    return map;
  }

  /// GET d'un entier JSON nu (ex. un compteur).
  Future<int> getInt(String path) async {
    final response = await _dio.get<dynamic>(path);
    final data = response.data;
    if (data is num) return data.toInt();
    if (data is String) return int.tryParse(data) ?? 0;
    return 0;
  }

  /// GET binaire (CSV, Excel, PDF, image).
  Future<Uint8List> getBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) return Uint8List(0);
    return Uint8List.fromList(data);
  }

  /// POST multipart (import CSV, photo).
  Future<Map<String, dynamic>> postForm(String path, FormData data) async {
    final response = await _dio.post<dynamic>(path, data: data);
    return _decodeMap(response.data) ?? <String, dynamic>{};
  }

  /// POST multipart binaire brut (`file`) pour upload d’images.
  Future<void> postMultipart(String path,
      {required List<int> bytes, required String contentType}) async {
    final part = MultipartFile.fromBytes(
      bytes,
      contentType: DioMediaType.parse(contentType),
      filename: 'upload',
    );
    await _dio.post<dynamic>(path, data: FormData.fromMap({'file': part}));
  }
}

/// Tranche de pagination Spring Boot.
class ApiPage {
  const ApiPage({
    required this.content,
    required this.last,
    required this.number,
    required this.totalElements,
  });

  final List<dynamic> content;
  final bool last;
  final int number;
  final int totalElements;
}