import '../models/relay_sync_exception.dart';

/// Async provider used by the engine to resolve request auth headers at send time.
///
/// Example:
/// ```dart
/// final AuthHeaderProvider authHeaderProvider = () async {
///   return <String, String>{'Authorization': 'Bearer token'};
/// };
/// ```
typedef AuthHeaderProvider = Future<Map<String, String>> Function();

/// Async callback used by the engine after receiving an unauthorized response.
///
/// Return `true` when token refresh succeeded and failed tasks may retry;
/// return `false` when refresh failed without throwing.
///
/// Example:
/// ```dart
/// final TokenRefreshHandler tokenRefreshHandler = () async {
///   // Trigger refresh flow.
///   return true;
/// };
/// ```
typedef TokenRefreshHandler = Future<bool> Function();

/// Configures how unauthorized responses should be handled.
class UnauthorizedHandlingConfig {
  /// Creates an immutable unauthorized handling configuration.
  UnauthorizedHandlingConfig({
    this.refreshTokenOnUnauthorized = true,
    this.maxRefreshAttempts = 1,
  }) {
    if (maxRefreshAttempts < 0) {
      throw const RelaySyncException(message: 'maxRefreshAttempts must be non-negative.');
    }
  }

  /// Whether to call a [TokenRefreshHandler] when 401/403-like responses occur.
  final bool refreshTokenOnUnauthorized;

  /// Maximum token refresh attempts per unauthorized handling flow.
  final int maxRefreshAttempts;

  /// Returns a modified copy.
  UnauthorizedHandlingConfig copyWith({
    bool? refreshTokenOnUnauthorized,
    int? maxRefreshAttempts,
  }) {
    final nextMax = maxRefreshAttempts ?? this.maxRefreshAttempts;
    if (nextMax < 0) {
      throw const RelaySyncException(message: 'maxRefreshAttempts must be non-negative.');
    }

    return UnauthorizedHandlingConfig(
      refreshTokenOnUnauthorized:
          refreshTokenOnUnauthorized ?? this.refreshTokenOnUnauthorized,
      maxRefreshAttempts: nextMax,
    );
  }

  /// Converts to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'refreshTokenOnUnauthorized': refreshTokenOnUnauthorized,
      'maxRefreshAttempts': maxRefreshAttempts,
    };
  }

  /// Creates config from JSON.
  factory UnauthorizedHandlingConfig.fromJson(Map<String, Object?> json) {
    final maxRefreshAttempts = (json['maxRefreshAttempts'] as int?) ?? 1;
    if (maxRefreshAttempts < 0) {
      throw const RelaySyncException(message: 'maxRefreshAttempts must be non-negative.');
    }

    return UnauthorizedHandlingConfig(
      refreshTokenOnUnauthorized:
          (json['refreshTokenOnUnauthorized'] as bool?) ?? true,
      maxRefreshAttempts: maxRefreshAttempts,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UnauthorizedHandlingConfig &&
            other.refreshTokenOnUnauthorized == refreshTokenOnUnauthorized &&
            other.maxRefreshAttempts == maxRefreshAttempts;
  }

  @override
  int get hashCode => Object.hash(refreshTokenOnUnauthorized, maxRefreshAttempts);
}
