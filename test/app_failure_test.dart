import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mariageplus_app/src/core/errors/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure retourne le bon message', () {
      const failure = NetworkFailure();
      expect(failure.userMessage, 'Réseau indisponible. Vérifiez votre connexion.');
    });

    test('UnauthorizedFailure retourne le bon message', () {
      const failure = UnauthorizedFailure();
      expect(failure.userMessage, 'Session expirée. Veuillez vous reconnecter.');
    });

    test('NotFoundFailure retourne le bon message', () {
      const failure = NotFoundFailure(resource: 'Invité');
      expect(failure.userMessage, 'Invité introuvable.');
    });

    test('ValidationFailure retourne la première erreur', () {
      final failure = ValidationFailure(errors: {
        'email': ['Email invalide'],
        'name': ['Nom requis'],
      });
      expect(failure.userMessage, 'Email invalide');
    });

    test('UnknownFailure retourne le message par défaut', () {
      final failure = UnknownFailure(cause: 'oops');
      expect(failure.userMessage, 'Une erreur inattendue est survenue.');
    });
  });

  group('mapDioErrorToFailure', () {
    test('401 -> UnauthorizedFailure', () {
      final error = DioException(requestOptions: RequestOptions(path: '/'), response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/')));
      expect(mapDioErrorToFailure(error), isA<UnauthorizedFailure>());
    });

    test('404 -> NotFoundFailure', () {
      final error = DioException(requestOptions: RequestOptions(path: '/'), response: Response(statusCode: 404, requestOptions: RequestOptions(path: '/')));
      expect(mapDioErrorToFailure(error), isA<NotFoundFailure>());
    });

    test('timeout -> NetworkFailure', () {
      final error = DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionTimeout);
      expect(mapDioErrorToFailure(error), isA<NetworkFailure>());
    });

    test('500 -> ServerFailure', () {
      final error = DioException(requestOptions: RequestOptions(path: '/'), response: Response(statusCode: 500, requestOptions: RequestOptions(path: '/')));
      expect(mapDioErrorToFailure(error), isA<ServerFailure>());
    });
  });
}
