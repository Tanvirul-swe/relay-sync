import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

void main() {
  group('AlwaysOnlineNetworkMonitor', () {
    test('always reports reliable connection', () async {
      const monitor = AlwaysOnlineNetworkMonitor();

      expect(await monitor.hasReliableConnection, isTrue);
      expect(await monitor.onStatusChanged.isEmpty, isTrue);

      await monitor.dispose();
    });
  });

  group('ManualNetworkMonitor', () {
    test('supports manual online/offline toggling', () async {
      final monitor = ManualNetworkMonitor(initiallyOnline: false);
      final events = <bool>[];
      final sub = monitor.onStatusChanged.listen(events.add);

      expect(await monitor.hasReliableConnection, isFalse);

      await monitor.setOnline();
      await monitor.setOffline();
      await monitor.setOnlineStatus(true);

      await Future<void>.delayed(Duration.zero);

      expect(events, [true, false, true]);
      expect(await monitor.hasReliableConnection, isTrue);

      await sub.cancel();
      await monitor.dispose();
    });

    test('stream is broadcast and duplicate status is ignored', () async {
      final monitor = ManualNetworkMonitor();

      expect(monitor.onStatusChanged.isBroadcast, isTrue);

      final eventsA = <bool>[];
      final eventsB = <bool>[];
      final subA = monitor.onStatusChanged.listen(eventsA.add);
      final subB = monitor.onStatusChanged.listen(eventsB.add);

      await monitor.setOnlineStatus(true);
      await monitor.setOffline();
      await monitor.setOffline();

      await Future<void>.delayed(Duration.zero);

      expect(eventsA, [false]);
      expect(eventsB, [false]);

      await subA.cancel();
      await subB.cancel();
      await monitor.dispose();
    });

    test('throws after dispose', () async {
      final monitor = ManualNetworkMonitor();
      await monitor.dispose();

      expect(() => monitor.onStatusChanged, throwsA(isA<RelaySyncException>()));
      expect(monitor.hasReliableConnection, throwsA(isA<RelaySyncException>()));
      expect(monitor.setOnline(), throwsA(isA<RelaySyncException>()));
    });
  });
}
