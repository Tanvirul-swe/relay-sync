import 'model_utils.dart';

/// Structured error details captured during sync execution.
class SyncError {
  /// Creates a new immutable [SyncError].
  const SyncError({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  /// Stable machine-readable error code.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional structured error payload.
  final Map<String, Object?> details;

  /// Returns a modified copy of this instance.
  SyncError copyWith({
    String? code,
    String? message,
    Map<String, Object?>? details,
  }) {
    return SyncError(
      code: code ?? this.code,
      message: message ?? this.message,
      details: details ?? this.details,
    );
  }

  /// Converts this value to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code,
      'message': message,
      'details': details,
    };
  }

  /// Creates an instance from JSON.
  factory SyncError.fromJson(Map<String, Object?> json) {
    return SyncError(
      code: json['code']! as String,
      message: json['message']! as String,
      details: Map<String, Object?>.from(
        (json['details'] as Map<Object?, Object?>?) ?? const <String, Object?>{},
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncError &&
            other.code == code &&
            other.message == message &&
            mapEquals(other.details, details);
  }

  @override
  int get hashCode {
    final detailsHash = Object.hashAll(
      details.entries.map((e) => Object.hash(e.key, e.value)),
    );
    return Object.hash(code, message, detailsHash);
  }
}
