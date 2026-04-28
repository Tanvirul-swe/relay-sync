/// Exception thrown by [SyncClient] implementations when request execution fails.
class SyncClientException implements Exception {
  /// Creates a client exception.
  const SyncClientException({
    required this.message,
    this.statusCode,
    this.retryable = false,
    this.permanent = false,
    this.unauthorized = false,
    this.conflict = false,
    this.cause,
  });

  /// Human-readable message.
  final String message;

  /// Optional HTTP status code when available.
  final int? statusCode;

  /// Whether the error is considered retryable.
  final bool retryable;

  /// Whether the error is considered permanent.
  final bool permanent;

  /// Whether the error maps to unauthorized status.
  final bool unauthorized;

  /// Whether the error maps to a conflict status.
  final bool conflict;

  /// Optional underlying error cause.
  final Object? cause;

  @override
  String toString() {
    return 'SyncClientException(message: $message, statusCode: $statusCode, '
        'retryable: $retryable, permanent: $permanent, unauthorized: $unauthorized, '
        'conflict: $conflict, cause: $cause)';
  }
}
