# relay_sync_flutter

Flutter integrations for `relay_sync`.

## Connectivity monitor

Use `ConnectivityPlusNetworkMonitor` when connectivity type is enough for your
sync gating.

```dart
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';

final engine = RelaySyncEngine(
  client: syncClient,
  storage: storage,
  networkMonitor: ConnectivityPlusNetworkMonitor(),
);
```

## Internet health check monitor

Use `InternetHealthCheckMonitor` when the device must also reach your API or a
health endpoint before sync runs.

```dart
final monitor = InternetHealthCheckMonitor(
  healthUrl: Uri.parse('https://api.example.com/health'),
  timeout: const Duration(seconds: 3),
);

final engine = RelaySyncEngine(
  client: syncClient,
  storage: storage,
  networkMonitor: monitor,
);
```

If no `healthUrl` or `pingUrl` is provided, the monitor only uses
`connectivity_plus` results. If a health URL is provided, failed requests,
non-2xx/3xx responses, and timeouts report `false`.

Dispose monitors when the owning app object is disposed:

```dart
await monitor.dispose();
```

## App lifecycle sync

Register `AppLifecycleSyncObserver` to trigger a sync pass when the app returns
to the foreground.

```dart
late final AppLifecycleSyncObserver lifecycleObserver;

Future<void> initializeSync() async {
  final controller = RelaySyncController(engine: engine);
  await controller.initialize();

  lifecycleObserver = AppLifecycleSyncObserver.forController(
    controller: controller,
  );
}

void disposeSync() {
  lifecycleObserver.dispose();
}
```
