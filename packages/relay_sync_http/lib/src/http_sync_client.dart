import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:relay_sync/relay_sync.dart';

/// package:http-backed [SyncClient] implementation.
class HttpSyncClient implements SyncClient {
  /// Creates a client using [client] for request execution.
  ///
  /// When [baseUri] is provided, relative task endpoints are resolved against it.
  HttpSyncClient({
    required http.Client client,
    Uri? baseUri,
  })  : _client = client,
        _baseUri = baseUri;

  final http.Client _client;
  final Uri? _baseUri;

  static const Set<int> _retryableStatusCodes = <int>{
    408,
    429,
    500,
    502,
    503,
    504
  };
  static const Set<int> _permanentStatusCodes = <int>{400, 403, 404, 422};

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    final requestHeaders = <String, String>{...task.headers, ...headers};

    try {
      final request = http.Request(
        task.method.name.toUpperCase(),
        _resolveEndpoint(task.endpoint),
      );
      request.headers.addAll(requestHeaders);

      if (_shouldSendBody(task.method)) {
        _ensureJsonContentType(request.headers);
        request.body = jsonEncode(task.body);
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapStatusCode(response.statusCode);
      }

      return SyncResponse(
        statusCode: response.statusCode,
        body: _toBodyMap(response.body),
        headers: response.headers,
      );
    } on SyncClientException {
      rethrow;
    } on TimeoutException catch (error) {
      throw SyncClientException(
        message: error.message ?? 'HTTP request timed out.',
        retryable: true,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw SyncClientException(
        message: error.message,
        retryable: true,
        cause: error,
      );
    } on FormatException catch (error) {
      throw SyncClientException(
        message: 'Invalid sync endpoint.',
        permanent: true,
        cause: error,
      );
    } catch (error) {
      throw SyncClientException(
        message: 'HTTP request failed.',
        cause: error,
      );
    }
  }

  /// Closes the underlying [http.Client].
  void close() {
    _client.close();
  }

  Uri _resolveEndpoint(String endpoint) {
    final uri = Uri.parse(endpoint);
    if (uri.hasScheme) {
      return uri;
    }
    final baseUri = _baseUri;
    if (baseUri == null) {
      throw SyncClientException(
        message: 'Relative sync endpoint requires a baseUri.',
        permanent: true,
      );
    }
    return baseUri.resolveUri(uri);
  }

  bool _shouldSendBody(SyncMethod method) {
    return method == SyncMethod.post ||
        method == SyncMethod.put ||
        method == SyncMethod.patch ||
        method == SyncMethod.delete;
  }

  void _ensureJsonContentType(Map<String, String> headers) {
    final hasContentType =
        headers.keys.any((key) => key.toLowerCase() == 'content-type');
    if (!hasContentType) {
      headers['content-type'] = 'application/json';
    }
  }

  Map<String, Object?> _toBodyMap(String data) {
    if (data.isEmpty) {
      return const <String, Object?>{};
    }

    try {
      final decoded = jsonDecode(data);
      if (decoded == null) {
        return const <String, Object?>{};
      }
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map<Object?, Object?>) {
        return Map<String, Object?>.from(decoded);
      }
      return <String, Object?>{'data': decoded};
    } on FormatException {
      return <String, Object?>{'data': data};
    }
  }

  SyncClientException _mapStatusCode(int statusCode) {
    final retryable = _retryableStatusCodes.contains(statusCode);
    final permanent = _permanentStatusCodes.contains(statusCode);
    final unauthorized = statusCode == 401;
    final conflict = statusCode == 409;

    return SyncClientException(
      message: 'HTTP request failed with status $statusCode.',
      statusCode: statusCode,
      retryable: retryable,
      permanent: permanent,
      unauthorized: unauthorized,
      conflict: conflict,
    );
  }
}
