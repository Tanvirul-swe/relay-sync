import 'log_redaction.dart';

/// Log severity for [RelaySyncLogger].
enum RelaySyncLogLevel { debug, info, warning, error }

/// Logging contract that can be wired into the engine.
abstract interface class RelaySyncLogger {
  /// Emits a log entry.
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  });
}

/// Logger that prints structured entries to console output.
class ConsoleRelaySyncLogger implements RelaySyncLogger {
  /// Creates a console logger.
  const ConsoleRelaySyncLogger({this.minLevel = RelaySyncLogLevel.info});

  /// Lowest level that will be printed.
  final RelaySyncLogLevel minLevel;

  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (level.index < minLevel.index) {
      return;
    }

    final safeContext = _redactContext(context);
    final buffer = StringBuffer()
      ..write('[relay_sync][${level.name}] $message')
      ..write(' context=$safeContext');

    if (error != null) {
      buffer.write(' error=$error');
    }
    if (stackTrace != null) {
      buffer.write(' stackTrace=$stackTrace');
    }

    print(buffer.toString());
  }

  Map<String, Object?> _redactContext(Map<String, Object?> context) {
    final safe = Map<String, Object?>.from(context);
    final headers = safe['headers'];
    if (headers is Map<String, String>) {
      safe['headers'] = LogRedaction.redactHeaders(headers);
    } else if (headers is Map<Object?, Object?>) {
      safe['headers'] = LogRedaction.redactHeaders(
        headers.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    }
    return safe;
  }
}

/// Logger implementation that ignores all logs.
class NoopRelaySyncLogger implements RelaySyncLogger {
  /// Creates a no-op logger.
  const NoopRelaySyncLogger();

  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {}
}
