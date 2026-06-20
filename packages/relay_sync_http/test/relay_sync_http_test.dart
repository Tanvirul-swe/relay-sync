import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_http/relay_sync_http.dart';
import 'package:test/test.dart';

SyncTask _task(String id, SyncMethod method, String endpoint) {
  final now = DateTime.parse('2026-04-28T00:00:00Z');
  return SyncTask(
    id: id,
    method: method,
    endpoint: endpoint,
    body: const <String, Object?>{'value': 1},
    headers: const <String, String>{'x-task': 'task'},
    metadata: SyncMetadata(taskId: id, method: method),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('HttpSyncClient', () {
    test('uses baseUri and supports GET/POST/PUT/PATCH/DELETE', () async {
      final calls = <String>[];
      final bodies = <String>[];
      final client = MockClient.streaming((request, bodyStream) async {
        calls.add('${request.method}:${request.url}');
        bodies.add(await bodyStream.bytesToString());

        expect(request.headers['x-task'], 'task');
        expect(request.headers['authorization'], 'Bearer token');

        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(<List<int>>[
            '{"ok":true,"method":"${request.method}"}'.codeUnits,
          ]),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });
      final syncClient = HttpSyncClient(
        client: client,
        baseUri: Uri.parse('https://api.example.com'),
      );

      final getRes = await syncClient.execute(
        _task('1', SyncMethod.get, '/items'),
        headers: const <String, String>{'authorization': 'Bearer token'},
      );
      final postRes = await syncClient.execute(
        _task('2', SyncMethod.post, '/items'),
        headers: const <String, String>{'authorization': 'Bearer token'},
      );
      final putRes = await syncClient.execute(
        _task('3', SyncMethod.put, '/items/1'),
        headers: const <String, String>{'authorization': 'Bearer token'},
      );
      final patchRes = await syncClient.execute(
        _task('4', SyncMethod.patch, '/items/1'),
        headers: const <String, String>{'authorization': 'Bearer token'},
      );
      final delRes = await syncClient.execute(
        _task('5', SyncMethod.delete, '/items/1'),
        headers: const <String, String>{'authorization': 'Bearer token'},
      );

      expect(getRes.statusCode, 200);
      expect(postRes.body['method'], 'POST');
      expect(putRes.body['method'], 'PUT');
      expect(patchRes.body['method'], 'PATCH');
      expect(delRes.body['method'], 'DELETE');

      expect(calls, <String>[
        'GET:https://api.example.com/items',
        'POST:https://api.example.com/items',
        'PUT:https://api.example.com/items/1',
        'PATCH:https://api.example.com/items/1',
        'DELETE:https://api.example.com/items/1',
      ]);
      expect(bodies.first, isEmpty);
      expect(bodies.skip(1), everyElement('{"value":1}'));
    });

    test('maps timeout and client errors to retryable SyncClientException',
        () async {
      final baseUri = Uri.parse('https://api.example.com');
      final errors = <Object>[
        TimeoutException('network'),
        http.ClientException('network'),
      ];

      for (final error in errors) {
        final client = MockClient.streaming((request, bodyStream) async {
          throw error;
        });
        final syncClient = HttpSyncClient(client: client, baseUri: baseUri);

        expect(
          () => syncClient.execute(
              _task('t-${error.runtimeType}', SyncMethod.get, '/items')),
          throwsA(
            isA<SyncClientException>()
                .having((e) => e.retryable, 'retryable', isTrue),
          ),
        );
      }
    });

    test('maps status codes to SyncClientException categories', () async {
      final baseUri = Uri.parse('https://api.example.com');

      Future<void> assertStatus(
        int statusCode, {
        required bool retryable,
        required bool permanent,
        required bool unauthorized,
        required bool conflict,
      }) async {
        final client = MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable(<List<int>>[
              '{"error":"x"}'.codeUnits,
            ]),
            statusCode,
          );
        });
        final syncClient = HttpSyncClient(client: client, baseUri: baseUri);

        try {
          await syncClient
              .execute(_task('s-$statusCode', SyncMethod.get, '/items'));
          fail('Expected SyncClientException for status $statusCode');
        } on SyncClientException catch (error) {
          expect(error.statusCode, statusCode);
          expect(error.retryable, retryable);
          expect(error.permanent, permanent);
          expect(error.unauthorized, unauthorized);
          expect(error.conflict, conflict);
        }
      }

      await assertStatus(408,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);
      await assertStatus(429,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);
      await assertStatus(500,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);
      await assertStatus(502,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);
      await assertStatus(503,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);
      await assertStatus(504,
          retryable: true,
          permanent: false,
          unauthorized: false,
          conflict: false);

      await assertStatus(400,
          retryable: false,
          permanent: true,
          unauthorized: false,
          conflict: false);
      await assertStatus(403,
          retryable: false,
          permanent: true,
          unauthorized: false,
          conflict: false);
      await assertStatus(404,
          retryable: false,
          permanent: true,
          unauthorized: false,
          conflict: false);
      await assertStatus(422,
          retryable: false,
          permanent: true,
          unauthorized: false,
          conflict: false);

      await assertStatus(401,
          retryable: false,
          permanent: false,
          unauthorized: true,
          conflict: false);
      await assertStatus(409,
          retryable: false,
          permanent: false,
          unauthorized: false,
          conflict: true);
    });

    test('wraps non-map and plain-text responses in data', () async {
      final client = MockClient((request) async => http.Response('ok', 200));
      final syncClient = HttpSyncClient(
        client: client,
        baseUri: Uri.parse('https://api.example.com'),
      );

      final response =
          await syncClient.execute(_task('text', SyncMethod.get, '/items'));

      expect(response.body, const <String, Object?>{'data': 'ok'});
    });
  });
}
