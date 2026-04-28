/// Supported HTTP methods for sync operations.
enum SyncMethod {
  /// GET request.
  get,

  /// POST request.
  post,

  /// PUT request.
  put,

  /// PATCH request.
  patch,

  /// DELETE request.
  delete,
}

/// Serialization helpers for [SyncMethod].
extension SyncMethodJson on SyncMethod {
  /// Converts this enum to its JSON representation.
  String toJson() => name;

  /// Parses [value] into a [SyncMethod].
  static SyncMethod fromJson(String value) {
    return SyncMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => throw FormatException('Invalid SyncMethod: $value'),
    );
  }
}

/// Status of a sync task in the queue lifecycle.
enum SyncTaskStatus {
  /// Task is waiting to be processed.
  pending,

  /// Task is currently syncing.
  syncing,

  /// Task failed and will be retried later.
  retryScheduled,

  /// Task completed successfully.
  synced,

  /// Task failed but may be retried.
  failedRetryable,

  /// Task failed permanently and will not be retried.
  failedPermanent,

  /// Task resulted in a conflict and needs resolution.
  conflict,

  /// Task was cancelled.
  cancelled,
}

/// Serialization helpers for [SyncTaskStatus].
extension SyncTaskStatusJson on SyncTaskStatus {
  /// Converts this enum to its JSON representation.
  String toJson() => name;

  /// Parses [value] into a [SyncTaskStatus].
  static SyncTaskStatus fromJson(String value) {
    return SyncTaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw FormatException('Invalid SyncTaskStatus: $value'),
    );
  }
}

/// Priority of queued sync tasks.
enum SyncPriority {
  /// Lowest priority.
  low,

  /// Default priority.
  normal,

  /// Higher-than-default priority.
  high,

  /// Highest possible priority.
  critical,
}

/// Serialization helpers for [SyncPriority].
extension SyncPriorityJson on SyncPriority {
  /// Converts this enum to its JSON representation.
  String toJson() => name;

  /// Parses [value] into a [SyncPriority].
  static SyncPriority fromJson(String value) {
    return SyncPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => throw FormatException('Invalid SyncPriority: $value'),
    );
  }
}
