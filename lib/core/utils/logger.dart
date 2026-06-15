import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void info(String message, {String tag = 'INFO'}) {
    _log('💡 [$tag] $message');
  }

  static void success(String message, {String tag = 'SUCCESS'}) {
    _log('✅ [$tag] $message');
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    _log('⚠️ [$tag] $message');
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'ERROR',
  }) {
    _log('❌ [$tag] $message', error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String tag = 'DEBUG'}) {
    _log('🐛 [$tag] $message');
  }

  static void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      error: error,
      stackTrace: stackTrace,
      name: 'APP_LOGGER',
    );
  }
}
