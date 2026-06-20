import 'model_utils.dart';
import 'sync_enums.dart';

/// Metadata associated with a queued sync task.
class SyncMetadata {
  /// Creates a new immutable [SyncMetadata].
  const SyncMetadata({
    required this.taskId,
    required this.method,
    this.userId,
    this.tenantId,
    this.priority = SyncPriority.normal,
    this.attempt = 0,
    this.maxAttempts = 3,
    this.dependsOnTaskIds = const <String>[],
    this.tags = const <String, String>{},
  });

  /// Unique task identifier.
  final String taskId;

  /// HTTP method used by the task.
  final SyncMethod method;

  /// Optional user scope.
  final String? userId;

  /// Optional tenant scope.
  final String? tenantId;

  /// Priority used by schedulers.
  final SyncPriority priority;

  /// Current attempt count.
  final int attempt;

  /// Max attempts before permanent failure.
  final int maxAttempts;

  /// Upstream task IDs this task depends on.
  final List<String> dependsOnTaskIds;

  /// Arbitrary tags for indexing/metrics.
  final Map<String, String> tags;

  /// Returns a modified copy of this instance.
  SyncMetadata copyWith({
    String? taskId,
    SyncMethod? method,
    String? userId,
    String? tenantId,
    SyncPriority? priority,
    int? attempt,
    int? maxAttempts,
    List<String>? dependsOnTaskIds,
    Map<String, String>? tags,
  }) {
    return SyncMetadata(
      taskId: taskId ?? this.taskId,
      method: method ?? this.method,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      priority: priority ?? this.priority,
      attempt: attempt ?? this.attempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      dependsOnTaskIds: dependsOnTaskIds ?? this.dependsOnTaskIds,
      tags: tags ?? this.tags,
    );
  }

  /// Converts this value to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'taskId': taskId,
      'method': method.toJson(),
      'userId': userId,
      'tenantId': tenantId,
      'priority': priority.toJson(),
      'attempt': attempt,
      'maxAttempts': maxAttempts,
      'dependsOnTaskIds': dependsOnTaskIds,
      'tags': tags,
    };
  }

  /// Creates an instance from JSON.
  factory SyncMetadata.fromJson(Map<String, Object?> json) {
    return SyncMetadata(
      taskId: json['taskId']! as String,
      method: SyncMethodJson.fromJson(json['method']! as String),
      userId: json['userId'] as String?,
      tenantId: json['tenantId'] as String?,
      priority: SyncPriorityJson.fromJson(json['priority']! as String),
      attempt: json['attempt']! as int,
      maxAttempts: json['maxAttempts']! as int,
      dependsOnTaskIds: List<String>.from(
        (json['dependsOnTaskIds'] as List<Object?>?) ?? const <String>[],
      ),
      tags: Map<String, String>.from(
        (json['tags'] as Map<Object?, Object?>?) ?? const <String, String>{},
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncMetadata &&
            other.taskId == taskId &&
            other.method == method &&
            other.userId == userId &&
            other.tenantId == tenantId &&
            other.priority == priority &&
            other.attempt == attempt &&
            other.maxAttempts == maxAttempts &&
            listEquals(other.dependsOnTaskIds, dependsOnTaskIds) &&
            mapEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(
        taskId,
        method,
        userId,
        tenantId,
        priority,
        attempt,
        maxAttempts,
        listHash(dependsOnTaskIds),
        mapHash(tags),
      );
}
