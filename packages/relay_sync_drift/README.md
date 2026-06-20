# relay_sync_drift

Drift-backed `SyncStorageAdapter` for `relay_sync`.

## Setup

Create a Drift database and pass it to `DriftSyncStorage`.

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_drift/relay_sync_drift.dart';

Future<DriftSyncStorage> createStorage() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, 'relay_sync.sqlite'));

  final database = RelaySyncDriftDatabase(NativeDatabase(file));
  final storage = DriftSyncStorage(database: database);
  await storage.initialize();
  return storage;
}
```

Use it with the engine:

```dart
final storage = await createStorage();

final engine = RelaySyncEngine(
  client: syncClient,
  storage: storage,
);

await engine.initialize();
```

Close the adapter when the owning app object is disposed:

```dart
await storage.close();
```

## Schema

`RelaySyncDriftDatabase` creates a `sync_tasks` table for queued `SyncTask`
snapshots. `body`, `headers`, `metadata`, `dependsOnTaskIds`, and `lastError`
are stored as JSON text by `DriftSyncStorage`.

The table defines indexes for:

- `status`
- `userId`
- `tenantId`
- `nextRetryAt`
- `priority`
- `createdAt`
- `dedupeKey`

## Watching

`watchTasks` and `watchCountByStatus` use Drift query streams, so listeners are
updated when rows in `sync_tasks` change.

```dart
final subscription = storage.watchTasks().listen((tasks) {
  // Render queue state or diagnostics.
});

await subscription.cancel();
```

## Tests

For tests, use Drift's in-memory native database:

```dart
final database = RelaySyncDriftDatabase(NativeDatabase.memory());
final storage = DriftSyncStorage(database: database);
await storage.initialize();
```
