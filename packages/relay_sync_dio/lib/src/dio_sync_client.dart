import 'package:dio/dio.dart';
import 'package:relay_sync/relay_sync.dart';

/// Dio-backed [SyncClient] implementation.
class DioSyncClient implements SyncClient {
  /// Creates a client with a configured [dio] instance.
  DioSyncClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const Set<int> _retryableStatusCodes = <int>{408, 429, 500, 502, 503, 504};
  static const Set<int> _permanentStatusCodes = <int>{400, 403, 404, 422};

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    final requestHeaders = <String, String>{...task.headers, ...headers};

    try {
      final response = await _dio.request<dynamic>(
        task.endpoint,
        data: _shouldSendBody(task.method) ? task.body : null,
        options: Options(
          method: task.method.name.toUpperCase(),
          headers: requestHeaders,
          responseType: ResponseType.json,
          contentType: Headers.jsonContentType,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      return SyncResponse(
        statusCode: statusCode,
        body: _toBodyMap(response.data),
        headers: response.headers.map.map(
          (key, values) => MapEntry(key, values.join(',')),
        ),
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  bool _shouldSendBody(SyncMethod method) {
    return method == SyncMethod.post ||
        method == SyncMethod.put ||
        method == SyncMethod.patch ||
        method == SyncMethod.delete;
  }

  Map<String, Object?> _toBodyMap(Object? data) {
    if (data == null) {
      return const <String, Object?>{};
    }
    if (data is Map<String, Object?>) {
      return data;
    }
    if (data is Map<Object?, Object?>) {
      return Map<String, Object?>.from(data);
    }
    return <String, Object?>{'data': data};
  }

  SyncClientException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    final timeoutOrConnection = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;

    final retryableByStatus = statusCode != null && _retryableStatusCodes.contains(statusCode);
    final permanentByStatus = statusCode != null && _permanentStatusCodes.contains(statusCode);
    final unauthorized = statusCode == 401;
    final conflict = statusCode == 409;

    return SyncClientException(
      message: error.message ?? 'Dio request failed.',
      statusCode: statusCode,
      retryable: timeoutOrConnection || retryableByStatus,
      permanent: permanentByStatus,
      unauthorized: unauthorized,
      conflict: conflict,
      cause: error,
    );
  }
}
