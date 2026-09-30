import 'package:dio/dio.dart';

/// Sealed class des erreurs métier / techniques de l'application.
sealed class AppFailure implements Exception {
  const AppFailure();

  String get userMessage;
  String? get technicalMessage => null;
}

/// Erreur réseau (timeout, DNS, connexion impossible).
final class NetworkFailure extends AppFailure {
  const NetworkFailure({this.cause});

  final Object? cause;

  @override
  String get userMessage => 'Réseau indisponible. Vérifiez votre connexion.';

  @override
  String? get technicalMessage =>
      cause != null ? 'Network error: $cause' : null;
}

/// Authentification expirée ou invalide.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();

  @override
  String get userMessage => 'Session expirée. Veuillez vous reconnecter.';
}

/// Ressource non trouvée (404).
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({required this.resource});

  final String resource;

  @override
  String get userMessage => '$resource introuvable.';
}

/// Erreur de validation renvoyée par le backend.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required this.errors});

  final Map<String, dynamic> errors;

  @override
  String get userMessage {
    final first = errors.values.firstOrNull;
    if (first is String) return first;
    if (first is List && first.isNotEmpty && first.first is String) {
      return first.first as String;
    }
    return 'Données invalides.';
  }
}

/// Erreur serveur générique (500, 502, 503).
final class ServerFailure extends AppFailure {
  const ServerFailure({this.statusCode, this.cause});

  final int? statusCode;
  final Object? cause;

  @override
  String get userMessage => 'Erreur serveur. Réessayez plus tard.';

  @override
  String? get technicalMessage =>
      'Server error ($statusCode): $cause';
}

/// Erreur inconnue / catch-all.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({required this.cause});

  final Object cause;

  @override
  String get userMessage => 'Une erreur inattendue est survenue.';

  @override
  String? get technicalMessage => cause.toString();
}

AppFailure mapDioErrorToFailure(DioException error) {
  if (error.response?.statusCode == 401) {
    return const UnauthorizedFailure();
  }
  if (error.response?.statusCode == 404) {
    return const NotFoundFailure(resource: 'Ressource');
  }
  if (error.response?.statusCode == 403) {
    return const NotFoundFailure(resource: 'Accès refusé');
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return NetworkFailure(cause: error);
  }
  if (error.response?.statusCode != null &&
      error.response!.statusCode! >= 500) {
    return ServerFailure(
      statusCode: error.response?.statusCode,
      cause: error.message,
    );
  }
  if (error.response?.data is Map) {
    return ValidationFailure(errors: error.response!.data as Map<String, dynamic>);
  }
  return ServerFailure(
    statusCode: error.response?.statusCode,
    cause: error.message,
  );
}
