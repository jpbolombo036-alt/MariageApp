import 'package:logger/logger.dart';

/// Logger global de l'application.
///
/// Les tokens et données sensibles ne doivent **jamais** être logués.
class AppLogger {
  static final Logger _instance = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
    level: bool.fromEnvironment('dart.vm.product') ? Level.info : Level.debug,
  );

  static Logger get instance => _instance;

  static void d(String message) => _instance.d(message);
  static void i(String message) => _instance.i(message);
  static void w(String message) => _instance.w(message);
  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _instance.e(message, error: error, stackTrace: stackTrace);
}
