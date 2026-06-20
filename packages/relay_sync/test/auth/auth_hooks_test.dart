import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

void main() {
  group('AuthHeaderProvider', () {
    test('supports simple async header provider', () async {
      Future<Map<String, String>> provider() async {
        return <String, String>{'Authorization': 'Bearer token'};
      }

      expect(await provider(), {'Authorization': 'Bearer token'});
    });

    test('propagates provider errors', () async {
      Future<Map<String, String>> provider() async {
        throw const RelaySyncException(message: 'token unavailable');
      }

      expect(provider(), throwsA(isA<RelaySyncException>()));
    });
  });

  group('TokenRefreshHandler', () {
    test('supports simple refresh handler', () async {
      Future<bool> handler() async => true;

      expect(await handler(), isTrue);
    });

    test('propagates refresh handler errors', () async {
      Future<bool> handler() async {
        throw const RelaySyncException(message: 'refresh failed');
      }

      expect(handler(), throwsA(isA<RelaySyncException>()));
    });
  });

  group('UnauthorizedHandlingConfig', () {
    test('has expected defaults', () {
      final config = UnauthorizedHandlingConfig();

      expect(config.refreshTokenOnUnauthorized, isTrue);
      expect(config.maxRefreshAttempts, 1);
    });

    test('supports copyWith and json roundtrip', () {
      final config = UnauthorizedHandlingConfig(
        refreshTokenOnUnauthorized: false,
        maxRefreshAttempts: 3,
      );

      final copied = config.copyWith(maxRefreshAttempts: 5);
      final parsed = UnauthorizedHandlingConfig.fromJson(config.toJson());

      expect(copied.maxRefreshAttempts, 5);
      expect(parsed, config);
    });

    test('throws when maxRefreshAttempts is negative', () {
      expect(
        () => UnauthorizedHandlingConfig(maxRefreshAttempts: -1),
        throwsA(isA<RelaySyncException>()),
      );
      expect(
        () => UnauthorizedHandlingConfig().copyWith(maxRefreshAttempts: -1),
        throwsA(isA<RelaySyncException>()),
      );
      expect(
        () => UnauthorizedHandlingConfig.fromJson(
          const <String, Object?>{'maxRefreshAttempts': -1},
        ),
        throwsA(isA<RelaySyncException>()),
      );
    });
  });
}
