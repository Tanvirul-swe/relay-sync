import 'sync_error.dart';

/// Exception thrown by relay_sync APIs.
class RelaySyncException implements Exception {
  /// Creates a new [RelaySyncException].
  const RelaySyncException({
    required this.message,
    this.error,
    this.cause,
  });

  /// Human-readable exception message.
  final String message;

  /// Optional structured sync error.
  final SyncError? error;

  /// Optional original cause.
  final Object? cause;

  @override
  String toString() {
    return 'RelaySyncException(message: $message, error: $error, cause: $cause)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RelaySyncException &&
            other.message == message &&
            other.error == error &&
            other.cause == cause;
  }

  @override
  int get hashCode => Object.hash(message, error, cause);
}
