# relay_sync_sqflite

Sqflite-backed `SyncStorageAdapter` for `relay_sync`.

## Setup

```dart
import 'package:path/path.dart' as p;
import 'package:relay_sync/relay_sync.dart';
import 'package:sqflite/sqflite.dart';
import 'package:relay_sync_sqflite/relay_sync_sqflite.dart';

final storage = SqfliteSyncStorage(
  databasePath: p.join(await getDatabasesPath(), 'relay_sync.db'),
);

await storage.initialize();
```

Pass the storage adapter to your engine:

```dart
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

`SqfliteSyncStorage` creates a `sync_tasks` table with columns matching
`SyncTask` fields. `body`, `headers`, `metadata`, `dependsOnTaskIds`, and
`lastError` are stored as JSON text. The adapter creates indexes for:

- `status`
- `userId`
- `tenantId`
- `nextRetryAt`
- `priority`
- `createdAt`
- `dedupeKey`

## Migrations

Set a higher `version` and provide migration callbacks when your app needs
additional tables or adapter-adjacent schema changes.

```dart
final storage = SqfliteSyncStorage(
  databasePath: databasePath,
  version: 2,
  migrations: <SqfliteSyncMigration>[
    (database, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await database.execute(
          'CREATE INDEX IF NOT EXISTS idx_my_extra_index ON sync_tasks (entityType)',
        );
      }
    },
  ],
);
```

The adapter always ensures the built-in `sync_tasks` table and required indexes
exist before running migration callbacks.
