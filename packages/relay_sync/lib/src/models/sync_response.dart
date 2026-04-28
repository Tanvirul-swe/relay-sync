import 'model_utils.dart';

/// Response data captured after an HTTP sync attempt.
class SyncResponse {
  /// Creates a new immutable [SyncResponse].
  const SyncResponse({
    required this.statusCode,
    this.body = const <String, Object?>{},
    this.headers = const <String, String>{},
  });

  /// HTTP status code.
  final int statusCode;

  /// Decoded response body.
  final Map<String, Object?> body;

  /// Response headers.
  final Map<String, String> headers;

  /// Returns a modified copy of this instance.
  SyncResponse copyWith({
    int? statusCode,
    Map<String, Object?>? body,
    Map<String, String>? headers,
  }) {
    return SyncResponse(
      statusCode: statusCode ?? this.statusCode,
      body: body ?? this.body,
      headers: headers ?? this.headers,
    );
  }

  /// Converts this value to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'statusCode': statusCode,
      'body': body,
      'headers': headers,
    };
  }

  /// Creates an instance from JSON.
  factory SyncResponse.fromJson(Map<String, Object?> json) {
    return SyncResponse(
      statusCode: json['statusCode']! as int,
      body: Map<String, Object?>.from(
        (json['body'] as Map<Object?, Object?>?) ?? const <String, Object?>{},
      ),
      headers: Map<String, String>.from(
        (json['headers'] as Map<Object?, Object?>?) ?? const <String, String>{},
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncResponse &&
            other.statusCode == statusCode &&
            mapEquals(other.body, body) &&
            mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => Object.hash(
        statusCode,
        Object.hashAll(body.entries),
        Object.hashAll(headers.entries),
      );
}
