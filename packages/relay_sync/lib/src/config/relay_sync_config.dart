import '../models/model_utils.dart';
import '../models/relay_sync_exception.dart';
import '../logging/relay_sync_logger.dart';
import '../metrics/relay_sync_metrics.dart';
import '../retry/exponential_backoff_retry_policy.dart';
import '../retry/retry_policy.dart';

/// Strategy used when a duplicate pending task is enqueued with the same dedupe key.
enum DeduplicationStrategy {
  /// Keep the first queued task and ignore newer duplicates.
  keepFirst,

  /// Replace existing pending duplicates with the newest task.
  keepLatest,

  /// Allow multiple pending tasks with the same dedupe key.
  allowDuplicates,
}

/// Immutable runtime configuration for relay_sync engine behavior.
class RelaySyncConfig {
  static final RetryPolicy _defaultRetryPolicy = ExponentialBackoffRetryPolicy(
    initialDelay: const Duration(seconds: 1),
    maxDelay: const Duration(seconds: 30),
    jitter: 0.2,
  );

  /// Creates a configuration instance with production-friendly defaults.
  RelaySyncConfig({
    this.autoSync = true,
    this.maxRetries = 5,
    this.maxConcurrentTasks = 1,
    this.deleteSyncedTasks = false,
    this.syncOnStart = true,
    this.syncOnNetworkRestore = true,
    RetryPolicy? retryPolicy,
    Map<String, String> defaultHeaders = const <String, String>{},
    this.userId,
    this.tenantId,
    this.requestTimeout = const Duration(seconds: 30),
    this.continueOnTaskFailure = true,
    this.enableDeduplication = true,
    this.deduplicationStrategy = DeduplicationStrategy.keepLatest,
    this.enableDependencyOrdering = true,
    this.logger,
    this.metrics,
  })  : retryPolicy = retryPolicy ?? _defaultRetryPolicy,
        defaultHeaders = Map<String, String>.unmodifiable(defaultHeaders) {
    _validate();
  }

  /// Automatically process queued tasks when possible.
  final bool autoSync;

  /// Maximum retry attempts per task.
  final int maxRetries;

  /// Max number of tasks to process concurrently.
  final int maxConcurrentTasks;

  /// Whether successful synced tasks should be deleted.
  final bool deleteSyncedTasks;

  /// Whether sync should run immediately when the engine starts.
  final bool syncOnStart;

  /// Whether sync should resume when network is restored.
  final bool syncOnNetworkRestore;

  /// Retry policy used to compute retry schedules.
  final RetryPolicy retryPolicy;

  /// Default headers attached to outgoing requests.
  final Map<String, String> defaultHeaders;

  /// Optional user scope for task filtering.
  final String? userId;

  /// Optional tenant scope for task filtering.
  final String? tenantId;

  /// Request timeout used by adapters.
  final Duration requestTimeout;

  /// Continue processing remaining tasks when one task fails.
  final bool continueOnTaskFailure;

  /// Enables duplicate task suppression using dedupe keys.
  final bool enableDeduplication;

  /// Strategy used to resolve duplicate pending tasks with the same dedupe key.
  final DeduplicationStrategy deduplicationStrategy;

  /// Enables dependency-aware task ordering.
  final bool enableDependencyOrdering;

  /// Optional logger implementation.
  final RelaySyncLogger? logger;

  /// Optional metrics implementation.
  final RelaySyncMetrics? metrics;

  /// Returns a copy with selected fields updated.
  RelaySyncConfig copyWith({
    bool? autoSync,
    int? maxRetries,
    int? maxConcurrentTasks,
    bool? deleteSyncedTasks,
    bool? syncOnStart,
    bool? syncOnNetworkRestore,
    RetryPolicy? retryPolicy,
    Map<String, String>? defaultHeaders,
    String? userId,
    String? tenantId,
    Duration? requestTimeout,
    bool? continueOnTaskFailure,
    bool? enableDeduplication,
    DeduplicationStrategy? deduplicationStrategy,
    bool? enableDependencyOrdering,
    RelaySyncLogger? logger,
    RelaySyncMetrics? metrics,
  }) {
    return RelaySyncConfig(
      autoSync: autoSync ?? this.autoSync,
      maxRetries: maxRetries ?? this.maxRetries,
      maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
      deleteSyncedTasks: deleteSyncedTasks ?? this.deleteSyncedTasks,
      syncOnStart: syncOnStart ?? this.syncOnStart,
      syncOnNetworkRestore: syncOnNetworkRestore ?? this.syncOnNetworkRestore,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      continueOnTaskFailure: continueOnTaskFailure ?? this.continueOnTaskFailure,
      enableDeduplication: enableDeduplication ?? this.enableDeduplication,
      deduplicationStrategy: deduplicationStrategy ?? this.deduplicationStrategy,
      enableDependencyOrdering:
          enableDependencyOrdering ?? this.enableDependencyOrdering,
      logger: logger ?? this.logger,
      metrics: metrics ?? this.metrics,
    );
  }

  void _validate() {
    if (maxRetries < 0) {
      throw const RelaySyncException(message: 'maxRetries must be non-negative.');
    }
    if (maxConcurrentTasks <= 0) {
      throw const RelaySyncException(message: 'maxConcurrentTasks must be greater than zero.');
    }
    if (requestTimeout.inMilliseconds <= 0) {
      throw const RelaySyncException(message: 'requestTimeout must be greater than zero.');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RelaySyncConfig &&
            other.autoSync == autoSync &&
            other.maxRetries == maxRetries &&
            other.maxConcurrentTasks == maxConcurrentTasks &&
            other.deleteSyncedTasks == deleteSyncedTasks &&
            other.syncOnStart == syncOnStart &&
            other.syncOnNetworkRestore == syncOnNetworkRestore &&
            other.retryPolicy == retryPolicy &&
            mapEquals(other.defaultHeaders, defaultHeaders) &&
            other.userId == userId &&
            other.tenantId == tenantId &&
            other.requestTimeout == requestTimeout &&
            other.continueOnTaskFailure == continueOnTaskFailure &&
            other.enableDeduplication == enableDeduplication &&
            other.deduplicationStrategy == deduplicationStrategy &&
            other.enableDependencyOrdering == enableDependencyOrdering &&
            other.logger == logger &&
            other.metrics == metrics;
  }

  @override
  int get hashCode => Object.hash(
        autoSync,
        maxRetries,
        maxConcurrentTasks,
        deleteSyncedTasks,
        syncOnStart,
        syncOnNetworkRestore,
        retryPolicy,
        Object.hashAll(defaultHeaders.entries),
        userId,
        tenantId,
        requestTimeout,
        continueOnTaskFailure,
        enableDeduplication,
        deduplicationStrategy,
        enableDependencyOrdering,
        logger,
        metrics,
      );
}
