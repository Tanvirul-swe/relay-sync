# relay_sync

`relay_sync` is a Dart/Flutter monorepo for building offline-first API request queue and sync workflows.

## Package family

### Core
- `packages/relay_sync` — pure Dart core contracts and models.

### Storage adapters
- `packages/relay_sync_hive` — Hive adapter for persisted queue storage.
- `packages/relay_sync_sqflite` — SQLite/sqflite adapter for mobile persistence.
- `packages/relay_sync_drift` — Drift adapter for typed SQL persistence.

### HTTP adapters
- `packages/relay_sync_dio` — Dio adapter for request execution.
- `packages/relay_sync_http` — `package:http` adapter for request execution.

### Flutter integration
- `packages/relay_sync_flutter` — Flutter-specific widgets and app lifecycle integration.

## Examples
- `examples/basic_dio_hive_app` — minimal setup with Dio + Hive.
- `examples/advanced_field_app` — advanced integration scenario placeholder.

## Monorepo commands

```bash
melos bootstrap
melos run analyze
melos run test
```
