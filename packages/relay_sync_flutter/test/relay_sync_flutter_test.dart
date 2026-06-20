import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';

void main() {
  group('ConnectivityPlusNetworkMonitor', () {
    test('maps connectivity results to reliable connection state', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      addTearDown(controller.close);

      var current = <ConnectivityResult>[ConnectivityResult.wifi];
      final monitor = ConnectivityPlusNetworkMonitor.custom(
        checkConnectivity: () async => current,
        onConnectivityChanged: controller.stream,
      );
      addTearDown(monitor.dispose);

      expect(await monitor.hasReliableConnection, isTrue);

      current = <ConnectivityResult>[ConnectivityResult.none];
      expect(await monitor.hasReliableConnection, isFalse);

      final statuses = <bool>[];
      final subscription = monitor.onStatusChanged.listen(statuses.add);
      addTearDown(subscription.cancel);

      controller.add(<ConnectivityResult>[ConnectivityResult.mobile]);
      controller.add(<ConnectivityResult>[ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, <bool>[true, false]);
    });
  });

  group('InternetHealthCheckMonitor', () {
    test('uses connectivity state when no health URL is configured', () async {
      final monitor = InternetHealthCheckMonitor.custom(
        checkConnectivity: () async => <ConnectivityResult>[
          ConnectivityResult.ethernet,
        ],
        onConnectivityChanged: const Stream<List<ConnectivityResult>>.empty(),
      );
      addTearDown(monitor.dispose);

      expect(await monitor.hasReliableConnection, isTrue);
    });

    test('returns false when health check fails', () async {
      final monitor = InternetHealthCheckMonitor.custom(
        checkConnectivity: () async => <ConnectivityResult>[
          ConnectivityResult.wifi,
        ],
        onConnectivityChanged: const Stream<List<ConnectivityResult>>.empty(),
        healthUrl: Uri.parse('https://api.example.com/health'),
        healthCheck: (_) async => false,
      );
      addTearDown(monitor.dispose);

      expect(await monitor.hasReliableConnection, isFalse);
    });

    test('returns false when health check times out', () async {
      final monitor = InternetHealthCheckMonitor.custom(
        checkConnectivity: () async => <ConnectivityResult>[
          ConnectivityResult.wifi,
        ],
        onConnectivityChanged: const Stream<List<ConnectivityResult>>.empty(),
        healthUrl: Uri.parse('https://api.example.com/health'),
        timeout: const Duration(milliseconds: 1),
        healthCheck: (_) => Completer<bool>().future,
      );
      addTearDown(monitor.dispose);

      expect(await monitor.hasReliableConnection, isFalse);
    });

    test('emits health checked statuses for connectivity changes', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      addTearDown(controller.close);

      var healthy = true;
      final monitor = InternetHealthCheckMonitor.custom(
        checkConnectivity: () async => <ConnectivityResult>[
          ConnectivityResult.wifi,
        ],
        onConnectivityChanged: controller.stream,
        healthUrl: Uri.parse('https://api.example.com/health'),
        healthCheck: (_) async => healthy,
      );
      addTearDown(monitor.dispose);

      final statuses = <bool>[];
      final subscription = monitor.onStatusChanged.listen(statuses.add);
      addTearDown(subscription.cancel);

      controller.add(<ConnectivityResult>[ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      healthy = false;
      controller.add(<ConnectivityResult>[ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);
      controller.add(<ConnectivityResult>[ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, <bool>[true, false]);
    });
  });

  group('AppLifecycleSyncObserver', () {
    test('triggers sync when app resumes', () async {
      var syncCount = 0;
      final observer = AppLifecycleSyncObserver(
        onResume: () async {
          syncCount += 1;
        },
        registerImmediately: false,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(syncCount, 1);
    });

    test('does not overlap resume syncs', () async {
      var syncCount = 0;
      final completer = Completer<void>();
      final observer = AppLifecycleSyncObserver(
        onResume: () {
          syncCount += 1;
          return completer.future;
        },
        registerImmediately: false,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(syncCount, 1);

      completer.complete();
      await Future<void>.delayed(Duration.zero);

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(syncCount, 2);
    });
  });
}
