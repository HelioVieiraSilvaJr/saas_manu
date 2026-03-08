import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Sistema de logging centralizado.
///
/// Logs são automaticamente desabilitados em produção (release mode).
class AppLogger {
  AppLogger._();

  static const String _tag = 'SaaS_Manu';

  /// Log de debug - informações de desenvolvimento
  static void debug(String message, {String? tag}) {
    _log('DEBUG', tag ?? _tag, message);
  }

  /// Log informativo - eventos importantes
  static void info(String message, {String? tag}) {
    _log('INFO', tag ?? _tag, message);
  }

  /// Log de aviso - atenção necessária
  static void warning(String message, {String? tag}) {
    _log('WARNING', tag ?? _tag, message);
  }

  /// Log de erro - erros capturados
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', tag ?? _tag, message);
    if (error != null) {
      _log('ERROR', tag ?? _tag, 'Error: $error');
    }
    if (stackTrace != null) {
      _log('ERROR', tag ?? _tag, 'StackTrace: $stackTrace');
    }
  }

  static void _log(String level, String tag, String message) {
    // Desabilitar logs em produção
    if (kReleaseMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$timestamp] [$level] [$tag] $message';

    if (kDebugMode) {
      developer.log(formattedMessage, name: tag, level: _levelToInt(level));
    }
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}
