# relay_sync_hive

Hive-backed storage adapter for `relay_sync`.

## Setup

1. Add dependencies:
   - `relay_sync`
   - `relay_sync_hive`
   - `hive`
2. Initialize Hive with an application directory before creating storage:

```dart
import 'package:hive/hive.dart';
import 'package:relay_sync_hive/relay_sync_hive.dart';

Future<void> main() async {
  Hive.init('/path/to/app/storage');

  final storage = HiveSyncStorage(boxName: 'my_sync_tasks');
  await storage.initialize();
}
```

`HiveSyncStorage` stores `SyncTask` as JSON maps in a Hive box for maintainable schema evolution.
