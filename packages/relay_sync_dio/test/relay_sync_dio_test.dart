import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_dio/relay_sync_dio.dart';
import 'package:test/test.dart';

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

SyncTask _task(String id, SyncMethod method, String endpoint) {
  final now = DateTime.parse('2026-04-28T00:00:00Z');
  return SyncTask(
    id: id,
    method: method,
    endpoint: endpoint,
    body: const <String, Object?>{'value': 1},
    metadata: SyncMetadata(taskId: id, method: method),
    createdAt: now,
    updatedAt: now,
  );
}

ResponseBody _jsonBody(int statusCode, Map<String, Object?> payload) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
    headers: <String, List<String>>{Headers.contentTypeHeader: <String>[Headers.jsonContentType]},
  );
}

void main() {
  group('DioSyncClient', () {
    test('uses Dio baseUrl and supports GET/POST/PUT/PATCH/DELETE', () async {
      final calls = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = _MockAdapter((options) async {
        calls.add('${options.method}:${options.uri}');
        return _jsonBody(200, <String, Object?>{'ok': true, 'method': options.method});
      });

      final client = DioSyncClient(dio: dio);

      final getRes = await client.execute(_task('1', SyncMethod.get, '/items'));
      final postRes = await client.execute(_task('2', SyncMethod.post, '/items'));
      final putRes = await client.execute(_task('3', SyncMethod.put, '/items/1'));
      final patchRes = await client.execute(_task('4', SyncMethod.patch, '/items/1'));
      final delRes = await client.execute(_task('5', SyncMethod.delete, '/items/1'));

      expect(getRes.statusCode, 200);
      expect(postRes.body['method'], 'POST');
      expect(putRes.body['method'], 'PUT');
      expect(patchRes.body['method'], 'PATCH');
      expect(delRes.body['method'], 'DELETE');

      expect(calls.first, 'GET:https://api.example.com/items');
      expect(calls.length, 5);
    });

    test('maps timeout and connection errors to retryable SyncClientException', () async {
      for (final type in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter((options) async {
          throw DioException(requestOptions: options, type: type, message: 'network');
        });

        final client = DioSyncClient(dio: dio);

        expect(
          () => client.execute(_task('t-${type.name}', SyncMethod.get, '/items')),
          throwsA(
            isA<SyncClientException>().having((e) => e.retryable, 'retryable', isTrue),
          ),
        );
      }
    });

    test('maps status codes to SyncClientException categories', () async {
      Future<void> assertStatus(
        int statusCode, {
        required bool retryable,
        required bool permanent,
        required bool unauthorized,
        required bool conflict,
      }) async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter((options) async {
          return _jsonBody(statusCode, <String, Object?>{'error': 'x'});
        });

        final client = DioSyncClient(dio: dio);

        try {
          await client.execute(_task('s-$statusCode', SyncMethod.get, '/items'));
          fail('Expected SyncClientException for status $statusCode');
        } on SyncClientException catch (error) {
          expect(error.statusCode, statusCode);
          expect(error.retryable, retryable);
          expect(error.permanent, permanent);
          expect(error.unauthorized, unauthorized);
          expect(error.conflict, conflict);
        }
      }

      await assertStatus(408, retryable: true, permanent: false, unauthorized: false, conflict: false);
      await assertStatus(429, retryable: true, permanent: false, unauthorized: false, conflict: false);
      await assertStatus(500, retryable: true, permanent: false, unauthorized: false, conflict: false);
      await assertStatus(502, retryable: true, permanent: false, unauthorized: false, conflict: false);
      await assertStatus(503, retryable: true, permanent: false, unauthorized: false, conflict: false);
      await assertStatus(504, retryable: true, permanent: false, unauthorized: false, conflict: false);

      await assertStatus(400, retryable: false, permanent: true, unauthorized: false, conflict: false);
      await assertStatus(403, retryable: false, permanent: true, unauthorized: false, conflict: false);
      await assertStatus(404, retryable: false, permanent: true, unauthorized: false, conflict: false);
      await assertStatus(422, retryable: false, permanent: true, unauthorized: false, conflict: false);

      await assertStatus(401, retryable: false, permanent: false, unauthorized: true, conflict: false);
      await assertStatus(409, retryable: false, permanent: false, unauthorized: false, conflict: true);
    });
  });
}
