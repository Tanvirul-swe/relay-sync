# relay_sync

**Offline-first API queue and sync orchestration for Flutter & Dart.**

relay_sync lets your app make API calls even when the device has no network. Every outgoing request becomes a `SyncTask` that is persisted locally and automatically flushed when connectivity is restored. Swap the storage and HTTP backend independently via a clean adapter pattern.

---

## Table of Contents

- [Project Motive](#project-motive)
- [Monorepo Structure](#monorepo-structure)
- [Core Concepts](#core-concepts)
  - [SyncTask lifecycle](#synctask-lifecycle)
  - [Status flow](#status-flow)
  - [HTTP status mapping](#http-status-mapping)
- [Quick Start](#quick-start)
- [Package Reference](#package-reference)
  - [relay_sync — core](#relay_sync--core)
  - [relay_sync_dio](#relay_sync_dio)
  - [relay_sync_http](#relay_sync_http)
  - [relay_sync_hive](#relay_sync_hive)
  - [relay_sync_sqflite](#relay_sync_sqflite)
  - [relay_sync_drift](#relay_sync_drift)
  - [relay_sync_flutter](#relay_sync_flutter)
- [Configuration Reference](#configuration-reference)
- [Retry Policies](#retry-policies)
- [Network Monitors](#network-monitors)
- [Auth & Token Refresh](#auth--token-refresh)
- [Deduplication](#deduplication)
- [Dependency Ordering](#dependency-ordering)
- [Logging & Metrics](#logging--metrics)
- [Writing a Custom Adapter](#writing-a-custom-adapter)
- [Examples](#examples)
- [Running Tests](#running-tests)

---

## Project Motive

Mobile apps that talk to APIs break the moment the network disappears. The typical fix — disabling buttons, showing "you're offline" toasts, losing user work — is a poor experience. relay_sync solves this by treating every outgoing API call as a **durable queue entry** rather than a fire-and-forget HTTP request.

**Goals:**

- Work entirely offline; never lose a user action.
- Survive app restarts (persistent storage adapters).
- Retry automatically with back-off when the server is temporarily unavailable.
- Handle conflicts and auth token expiry gracefully.
- Keep the core pure Dart so it can run in any Dart environment.
- Let you plug in whichever HTTP client and storage you already use.

**Non-goals:**

- Full two-way sync / CRDT conflict resolution (tasks represent outgoing writes only).
- Server-side code — relay_sync is a client library.

---

## Monorepo Structure

```
relay-sync/
├── packages/
│   ├── relay_sync/            # Pure-Dart core — engine, models, interfaces
│   ├── relay_sync_dio/        # HTTP adapter using Dio
│   ├── relay_sync_http/       # HTTP adapter using package:http
│   ├── relay_sync_hive/       # Storage adapter using Hive
│   ├── relay_sync_sqflite/    # Storage adapter using sqflite
│   ├── relay_sync_drift/      # Storage adapter using Drift (type-safe SQL)
│   └── relay_sync_flutter/    # Flutter-specific helpers (lifecycle, connectivity)
└── examples/
    ├── advanced_field_app/    # Full offline-first field editor demo (Flutter)
    └── basic_dio_hive_app/    # Minimal wiring demo — Dio + Hive (Flutter)
```

Every adapter package depends only on `relay_sync` (core) plus its own third-party dependency. The core has **zero runtime dependencies**.

---

## Core Concepts

### SyncTask lifecycle

A `SyncTask` is an immutable snapshot of one outgoing API call. It carries everything needed to send the request later:

| Field | Purpose |
|---|---|
| `id` | Unique task identifier |
| `method` | HTTP verb (`get`, `post`, `put`, `patch`, `delete`) |
| `endpoint` | Path or full URL |
| `body` | Request payload (JSON map) |
| `headers` | Per-task request headers |
| `metadata` | Tags, user/tenant scope, dependency list |
| `status` | Current lifecycle state (see below) |
| `priority` | `low` / `normal` / `high` / `critical` |
| `retryCount` | Attempts so far |
| `maxRetries` | Limit before permanent failure |
| `createdAt` / `updatedAt` | Timestamps |
| `lastAttemptAt` | When the last send was tried |
| `nextRetryAt` | Scheduled retry time |
| `idempotencyKey` | Optional server-side idempotency header value |
| `dedupeKey` | Key used for duplicate suppression |
| `lastError` | Structured error from the last attempt |

### Status flow

```
                      ┌──────────────────────────────────────┐
                      │              pending                  │ ◄─── enqueue()
                      └────────────────┬─────────────────────┘
                                       │ syncNow()
                                       ▼
                      ┌──────────────────────────────────────┐
                      │              syncing                  │
                      └──┬──────────┬──────────┬─────────────┘
                         │          │          │
                    2xx  │    409   │  5xx /   │  4xx (perm)
                         │          │  timeout │
                         ▼          ▼          ▼
                      synced    conflict   retryScheduled ──► pending (retryAllFailed)
                                               │
                                   retries exhausted
                                               ▼
                                        failedRetryable ──► pending (retryAllFailed)
                                               │
                                   (no retry policy)
                                               ▼
                                        failedPermanent
```

`cancelled` is a terminal state set manually via `RelaySyncController.cancelTask()`.

### HTTP status mapping

| Status code | Outcome |
|---|---|
| 2xx | `synced` (or deleted if `deleteSyncedTasks: true`) |
| 401 | Triggers `tokenRefreshHandler`; retries once if refresh succeeds |
| 409 | `conflict` — waits for manual resolution |
| 408, 429, 5xx | Retryable — scheduled per retry policy |
| 400, 403, 404, 422 | `failedPermanent` — not retried |
| Transport / timeout | Retryable — same as 5xx |

---

## Quick Start

### 1. Add dependencies

```yaml
# pubspec.yaml
dependencies:
  relay_sync:
    path: packages/relay_sync          # or pub.dev version when published
  relay_sync_dio:
    path: packages/relay_sync_dio
  relay_sync_hive:
    path: packages/relay_sync_hive
  hive_flutter: ^1.1.0                 # required for Hive.initFlutter()
  dio: ^5.4.3+1

  # Flutter apps should also add:
  relay_sync_flutter:
    path: packages/relay_sync_flutter
```

### 2. Initialize in `main()`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();           // required before HiveSyncStorage
  runApp(const MyApp());
}
```

### 3. Build the stack

```dart
// Create once — typically in a StatefulWidget.initState or a service locator.
final storage   = HiveSyncStorage(boxName: 'my_app_tasks');
final client    = DioSyncClient(dio: Dio(BaseOptions(baseUrl: 'https://api.example.com')));
final monitor   = ManualNetworkMonitor(initiallyOnline: false);

final engine = RelaySyncEngine(
  storage: storage,
  client:  client,
  networkMonitor: monitor,
  config: RelaySyncConfig(
    autoSync: false,
    syncOnNetworkRestore: true,
    retryPolicy: ExponentialBackoffRetryPolicy(
      initialDelay: const Duration(seconds: 2),
      maxDelay:     const Duration(minutes: 2),
      jitter:       0.2,
    ),
  ),
);

final controller = RelaySyncController(engine: engine);
await controller.initialize();       // opens storage, wires network listener
```

### 4. Enqueue work

```dart
// Convenience methods on the controller:
await controller.post('/v1/orders', body: {'sku': 'ABC', 'qty': 2});
await controller.patch('/v1/profile', body: {'name': 'Alice'}, dedupeKey: 'profile');
await controller.delete('/v1/items/42');
```

### 5. Drive sync

```dart
// Manual trigger:
await controller.syncNow();

// Or set syncOnNetworkRestore: true in config and let the engine
// auto-sync whenever the ManualNetworkMonitor reports connectivity.
await monitor.setOnlineStatus(true);
```

### 6. Observe the queue

```dart
// All streams are broadcast and live-update from storage.
controller.watchTasks().listen((tasks) {
  // tasks: List<SyncTask> sorted by createdAt desc
});

controller.watchStatusCounts().listen((counts) {
  // counts: Map<SyncTaskStatus, int>
  final pending = counts[SyncTaskStatus.pending] ?? 0;
});

controller.watchState().listen((state) {
  // state: RelaySyncState — idle | syncing | paused | disposed
});
```

### 7. Teardown

```dart
await controller.dispose();   // disposes engine, closes storage, cancels subscriptions
```

---

## Package Reference

### `relay_sync` — core

**Pure Dart. No Flutter dependency. Zero runtime deps.**

Everything else is built on top of this package.

#### Key classes

| Class | Role |
|---|---|
| `RelaySyncEngine` | Orchestrates the sync loop, state machine, retry logic |
| `RelaySyncController` | Developer-facing API wrapping the engine |
| `RelaySyncConfig` | Immutable runtime configuration |
| `SyncTask` | Immutable unit of work |
| `SyncMetadata` | Supplementary metadata attached to a task |
| `SyncError` | Structured error captured after a failed attempt |
| `SyncResponse` | Decoded HTTP response |
| `SyncStorageAdapter` | Interface all storage adapters implement |
| `SyncClient` | Interface all HTTP clients implement |
| `NetworkMonitor` | Interface all connectivity monitors implement |
| `RetryPolicy` | Interface all retry strategies implement |
| `AuthHeaderProvider` | `typedef` — async supplier of auth headers |
| `TokenRefreshHandler` | `typedef` — async 401 recovery callback |

#### Enums

```dart
enum SyncTaskStatus { pending, syncing, retryScheduled, synced,
                      failedRetryable, failedPermanent, conflict, cancelled }

enum SyncMethod   { get, post, put, patch, delete }
enum SyncPriority { low, normal, high, critical }
enum RelaySyncState { idle, syncing, paused, disposed }
enum DeduplicationStrategy { keepFirst, keepLatest, allowDuplicates }
```

#### `RelaySyncController` API

```dart
// Initialization / teardown
Future<void> initialize()
Future<void> dispose()

// Enqueue helpers
Future<SyncTask> get(String endpoint,    { priority, dedupeKey, tags, ... })
Future<SyncTask> post(String endpoint,   { body, priority, dedupeKey, ... })
Future<SyncTask> put(String endpoint,    { body, priority, ... })
Future<SyncTask> patch(String endpoint,  { body, priority, dedupeKey, ... })
Future<SyncTask> delete(String endpoint, { priority, ... })
Future<void>     enqueue(SyncTask task)  // full control

// Control
Future<void> syncNow()
Future<void> pause()
Future<void> resume()
Future<void> cancelTask(String taskId)
Future<void> retryTask(String taskId)
Future<void> retryAllFailed()
Future<void> clearSynced()

// Streams
Stream<List<SyncTask>>              watchTasks()
Stream<Map<SyncTaskStatus, int>>    watchStatusCounts()
Stream<RelaySyncState>              watchState()
```

#### Built-in storage

`InMemorySyncStorage` — in-process only, lost on restart. Ideal for tests and demos.

#### Built-in network monitors

`ManualNetworkMonitor(initiallyOnline: bool)` — programmatically toggle connectivity.  
`AlwaysOnlineNetworkMonitor` — always reports `true`; useful in unit testing.

---

### `relay_sync_dio`

Dio-backed `SyncClient`.

```yaml
dependencies:
  relay_sync_dio:
    path: packages/relay_sync_dio
  dio: ^5.4.3+1
```

```dart
import 'package:dio/dio.dart';
import 'package:relay_sync_dio/relay_sync_dio.dart';

final client = DioSyncClient(
  dio: Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  )),
);
```

`DioSyncClient` maps `DioException` to `SyncClientException` automatically:

| Dio error / status | relay_sync outcome |
|---|---|
| connectionTimeout, sendTimeout, receiveTimeout, connectionError | Retryable |
| 408, 429, 500–504 | Retryable |
| 400, 403, 404, 422 | Permanent failure |
| 401 | Unauthorized → triggers token refresh |
| 409 | Conflict |

Body is sent as JSON for `POST`, `PUT`, `PATCH`, `DELETE`; omitted for `GET`.

---

### `relay_sync_http`

`package:http`-backed `SyncClient`. Lighter alternative to Dio.

```yaml
dependencies:
  relay_sync_http:
    path: packages/relay_sync_http
  http: ^1.2.1
```

```dart
import 'package:http/http.dart' as http;
import 'package:relay_sync_http/relay_sync_http.dart';

final client = HttpSyncClient(
  client:  http.Client(),
  baseUri: Uri.parse('https://api.example.com'),
);
```

When `baseUri` is provided, relative endpoint strings (e.g. `/v1/items`) are resolved against it. Same status-code mapping as `DioSyncClient`.

---

### `relay_sync_hive`

Hive-backed `SyncStorageAdapter`. Tasks persist across app restarts.

```yaml
dependencies:
  relay_sync_hive:
    path: packages/relay_sync_hive
  hive_flutter: ^1.1.0   # provides Hive.initFlutter()
```

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:relay_sync_hive/relay_sync_hive.dart';

// In main():
await Hive.initFlutter();

// In your service / StatefulWidget:
final storage = HiveSyncStorage(boxName: 'my_tasks');
await storage.initialize();   // opens the Hive box — must call before use
```

Tasks are stored as JSON maps inside the named Hive box. Multiple `HiveSyncStorage` instances with different `boxName` values can coexist safely (useful for multi-user or multi-tenant apps).

**Watch streams** are powered by `Box.watch()` and emit on every box mutation, so your UI rebuilds reactively without polling.

---

### `relay_sync_sqflite`

SQLite-backed `SyncStorageAdapter` via sqflite.

```yaml
dependencies:
  relay_sync_sqflite:
    path: packages/relay_sync_sqflite
  sqflite: ^2.4.2+1
  path_provider: ^2.1.0   # to locate the DB file
  path: ^1.9.0
```

```dart
import 'package:relay_sync_sqflite/relay_sync_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final dir     = await getApplicationDocumentsDirectory();
final dbPath  = p.join(dir.path, 'relay_sync.db');

final storage = SqfliteSyncStorage(
  databasePath: dbPath,
  version: 1,
  migrations: <SqfliteSyncMigration>[
    // add custom columns in future versions
  ],
);
await storage.initialize();
```

Schema migrations are supported via the `migrations` list. Each migration callback receives `(Database database, int oldVersion, int newVersion)`.

---

### `relay_sync_drift`

Type-safe SQL storage adapter via [Drift](https://drift.simonbinder.eu/).

```yaml
dependencies:
  relay_sync_drift:
    path: packages/relay_sync_drift
  drift: ^2.32.1
```

```dart
import 'package:relay_sync_drift/relay_sync_drift.dart';

// Create and open your Drift database (see Drift docs for NativeDatabase setup):
final db      = RelaySyncDriftDatabase(NativeDatabase(File('relay_sync.db')));
final storage = DriftSyncStorage(database: db);
await storage.initialize();
```

`RelaySyncDriftDatabase` is the generated Drift database class included in the package. Use it as-is or extend it for your own tables.

---

### `relay_sync_flutter`

Flutter-specific helpers. Depends on `relay_sync` + `connectivity_plus` + `package:http`.

```yaml
dependencies:
  relay_sync_flutter:
    path: packages/relay_sync_flutter
```

#### `ConnectivityPlusNetworkMonitor`

Reads live connectivity from `connectivity_plus`. Replaces `ManualNetworkMonitor` in production.

```dart
import 'package:relay_sync_flutter/relay_sync_flutter.dart';

final monitor = ConnectivityPlusNetworkMonitor();
// or inject a Connectivity instance:
final monitor = ConnectivityPlusNetworkMonitor(connectivity: Connectivity());
```

Reports `hasReliableConnection = true` whenever at least one non-`none` connectivity result is present.

#### `InternetHealthCheckMonitor`

Performs an actual HTTP GET to a health endpoint to confirm real internet, not just a local network connection.

```dart
final monitor = InternetHealthCheckMonitor(
  healthUrl: Uri.parse('https://api.example.com/health'),
  timeout:   const Duration(seconds: 5),
);
```

Returns `true` only when connectivity_plus reports a network type **and** the health endpoint responds 2xx/3xx. Falls back to `false` on any error or timeout.

#### `AppLifecycleSyncObserver`

Triggers a sync whenever the app returns to the foreground (`AppLifecycleState.resumed`).

```dart
// In your widget:
late final AppLifecycleSyncObserver _observer;

@override
void initState() {
  super.initState();
  // auto-registers with WidgetsBinding:
  _observer = AppLifecycleSyncObserver.forController(controller: _controller);
}

@override
void dispose() {
  _observer.dispose();
  super.dispose();
}
```

Guards against concurrent syncs with an in-flight flag, so rapid resume events do not stack.

#### `RelaySyncFlutter`

Lightweight integration marker. Useful as a runtime type label in logs and debug UIs.

```dart
final integration = const RelaySyncFlutter();
print(integration.runtimeType); // RelaySyncFlutter
```

---

## Configuration Reference

`RelaySyncConfig` is immutable. Pass it when constructing `RelaySyncEngine`.

```dart
RelaySyncConfig({
  // --- sync triggers ---
  bool autoSync               = true,   // sync immediately after every enqueue
  bool syncOnStart            = true,   // sync when engine.initialize() is called
  bool syncOnNetworkRestore   = true,   // sync when network comes back online

  // --- concurrency & retries ---
  int  maxConcurrentTasks     = 1,      // tasks to process in parallel per pass
  int  maxRetries             = 5,      // global max retries (per-task can override)
  RetryPolicy? retryPolicy,             // default: ExponentialBackoff(1s–30s, jitter 0.2)
  Duration requestTimeout     = const Duration(seconds: 30),

  // --- task lifecycle ---
  bool deleteSyncedTasks      = false,  // delete from storage once synced
  bool continueOnTaskFailure  = true,   // keep processing other tasks after one fails

  // --- deduplication ---
  bool enableDeduplication                          = true,
  DeduplicationStrategy deduplicationStrategy       = DeduplicationStrategy.keepLatest,

  // --- dependency ordering ---
  bool enableDependencyOrdering = true,

  // --- scoping ---
  String? userId,     // filter tasks to this user
  String? tenantId,   // filter tasks to this tenant

  // --- headers ---
  Map<String, String> defaultHeaders = const {},  // merged into every request

  // --- observability ---
  RelaySyncLogger?  logger,
  RelaySyncMetrics? metrics,
})
```

Use `config.copyWith(...)` to derive modified configs without constructing from scratch.

---

## Retry Policies

All retry policies implement `RetryPolicy`:

```dart
abstract class RetryPolicy {
  bool shouldRetry({ required int retryCount, required int maxRetries });
  DateTime? nextRetryAt({ required DateTime now, required int retryCount, required int maxRetries });
}
```

### `NoRetryPolicy`

Never retries. Tasks fail permanently on the first error.

```dart
const NoRetryPolicy()
```

### `FixedRetryPolicy`

Retries with a constant delay between attempts.

```dart
FixedRetryPolicy(delay: const Duration(seconds: 10))
```

### `ExponentialBackoffRetryPolicy`

Retries with exponentially growing delays, with optional randomisation (jitter) to avoid thundering herd.

```dart
ExponentialBackoffRetryPolicy(
  initialDelay: const Duration(seconds: 1),
  maxDelay:     const Duration(minutes: 5),
  multiplier:   2.0,   // delay doubles each attempt (default)
  jitter:       0.2,   // ±20 % random variance
)
```

Delay formula: `min(initialDelay × multiplier^retryCount, maxDelay) ± jitter%`

---

## Network Monitors

All monitors implement `NetworkMonitor`:

```dart
abstract interface class NetworkMonitor {
  Stream<bool> get onStatusChanged;       // emits true/false on every change
  Future<bool> get hasReliableConnection; // point-in-time check
  Future<void> dispose();
}
```

| Monitor | Package | When to use |
|---|---|---|
| `ManualNetworkMonitor` | `relay_sync` | Tests, demos, UI toggle |
| `AlwaysOnlineNetworkMonitor` | `relay_sync` | Unit tests that assume connectivity |
| `ConnectivityPlusNetworkMonitor` | `relay_sync_flutter` | Production — basic network type check |
| `InternetHealthCheckMonitor` | `relay_sync_flutter` | Production — validated real internet |

---

## Auth & Token Refresh

Pass `authHeaderProvider` and/or `tokenRefreshHandler` directly to `RelaySyncEngine`:

```dart
final engine = RelaySyncEngine(
  storage: storage,
  client:  client,
  networkMonitor: monitor,
  config:  config,

  // Called before every request to inject fresh tokens:
  authHeaderProvider: () async {
    final token = await myAuthService.getAccessToken();
    return {'Authorization': 'Bearer $token'};
  },

  // Called once when a 401 response is received:
  tokenRefreshHandler: () async {
    try {
      await myAuthService.refreshToken();
      return true;   // engine retries the task with fresh token
    } catch (_) {
      return false;  // refresh failed — task moves to failedPermanent
    }
  },
);
```

`authHeaderProvider` headers are resolved at send time, so tokens are always fresh even for tasks that were queued hours earlier. They are merged on top of `config.defaultHeaders` and per-task `headers`.

---

## Deduplication

When `enableDeduplication: true` (default), tasks with the same `dedupeKey` in `pending` state are collapsed according to `deduplicationStrategy`:

| Strategy | Behaviour |
|---|---|
| `keepLatest` (default) | Delete all existing pending duplicates; keep the new task |
| `keepFirst` | Ignore the new task; keep the existing one |
| `allowDuplicates` | No deduplication at all |

```dart
// Only the most recent PATCH to /profile will sit in the queue:
await controller.patch('/v1/profile',
  body: {'name': 'Alice'},
  dedupeKey: 'user-profile',
);
await controller.patch('/v1/profile',
  body: {'name': 'Alice Smith'},   // replaces the previous pending task
  dedupeKey: 'user-profile',
);
```

Deduplication only applies to `pending` tasks. Tasks already in `syncing`, `synced`, or failed states are never touched.

---

## Dependency Ordering

A task can declare that it must not start until other tasks have completed successfully.

```dart
final createOrder = await controller.post('/v1/orders',
  body: {'sku': 'ABC'},
);

// This task will not be processed until createOrder is synced:
await controller.post('/v1/order-items',
  body: {'orderId': createOrder.id, 'qty': 3},
  dependsOnTaskIds: [createOrder.id],
);
```

If `enableDependencyOrdering: true` (default) and a dependency ends up `failedPermanent` or `cancelled`, the dependent task is also marked `failedPermanent` automatically with `code: 'dependency_failed'`.

---

## Logging & Metrics

### Logger

Implement `RelaySyncLogger` and pass it to `RelaySyncConfig`:

```dart
class MyLogger implements RelaySyncLogger {
  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    debugPrint('[relay_sync/${level.name}] $message $context');
  }
}
```

Log levels: `debug`, `info`, `warning`, `error`.  
Authorization header values in log context are automatically redacted via `LogRedaction.redactHeaders()`.

### Metrics

Implement `RelaySyncMetrics` to push counters and timings to your analytics or APM system:

```dart
class MyMetrics implements RelaySyncMetrics {
  @override
  void increment(String name, { int value = 1, Map<String, String> tags = const {} }) {
    statsD.increment(name, value: value, tags: tags);
  }

  @override
  void timing(String name, Duration duration, { Map<String, String> tags = const {} }) {
    statsD.timing(name, duration.inMilliseconds, tags: tags);
  }
}
```

Named events emitted by the engine:

| Metric name | Type | Description |
|---|---|---|
| `syncStarted` | counter | A sync pass began |
| `syncCompleted` | counter | A sync pass finished |
| `syncDuration` | timing | Total wall time of a sync pass |
| `syncPaused` | counter | Engine paused (error or manual) |
| `syncResumed` | counter | Engine resumed |
| `taskEnqueued` | counter | A task was added to the queue |
| `taskSyncStarted` | counter | A task started sending |
| `taskSynced` | counter | A task completed successfully |
| `taskRetryScheduled` | counter | A task was scheduled for retry |
| `taskConflict` | counter | A task received a 409 response |
| `taskFailedPermanent` | counter | A task failed permanently |

---

## Writing a Custom Adapter

### Custom storage

Implement `SyncStorageAdapter` and plug it into `RelaySyncEngine`:

```dart
class MyCustomStorage implements SyncStorageAdapter {
  @override Future<void>    initialize() async { /* open connection */ }
  @override Future<void>    saveTask(SyncTask task) async { /* insert */ }
  @override Future<void>    updateTask(SyncTask task) async { /* update */ }
  @override Future<void>    upsertTask(SyncTask task) async { /* insert or replace */ }
  @override Future<SyncTask?> getTaskById(String id) async { /* select */ }
  @override Future<List<SyncTask>> getPendingTasks({...}) async { /* query */ }
  @override Future<List<SyncTask>> getRetryableTasks({...}) async { /* query */ }
  @override Future<List<SyncTask>> getFailedTasks({...}) async { /* query */ }
  @override Future<List<SyncTask>> getTasksByStatus(SyncTaskStatus s, {...}) async { /* query */ }
  @override Future<void>    deleteTask(String id) async { /* delete */ }
  @override Future<void>    clearSynced({...}) async { /* delete where synced */ }
  @override Future<void>    clearAll({...}) async { /* delete all */ }
  @override Future<Map<SyncTaskStatus, int>> countByStatus({...}) async { /* aggregate */ }
  @override Stream<List<SyncTask>>           watchTasks({...}) { /* broadcast stream */ }
  @override Stream<Map<SyncTaskStatus, int>> watchCountByStatus({...}) { /* broadcast stream */ }
  @override Future<void> close() async { /* release resources */ }
}
```

Use `SyncTask.toJson()` / `SyncTask.fromJson()` to serialise tasks into any JSON-compatible backend.

### Custom HTTP client

Implement `SyncClient` (1 method):

```dart
class MyHttpClient implements SyncClient {
  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const {},
  }) async {
    // send the request, return SyncResponse(statusCode, body, headers)
    // throw SyncClientException for transport errors
  }
}
```

`SyncClientException` fields that control task routing:

| Field | Effect when `true` |
|---|---|
| `retryable` | Task → `retryScheduled` |
| `permanent` | Task → `failedPermanent` |
| `unauthorized` | Triggers `tokenRefreshHandler` |
| `conflict` | Task → `conflict` |

---

## Examples

### `advanced_field_app`

**Location:** `examples/advanced_field_app/`  
**Stack:** `relay_sync` core + `relay_sync_flutter`

A guided 5-step offline-first field editor. Demonstrates:

- Queuing edits while the device is offline
- Live task list and status counts via `watchTasks()` / `watchStatusCounts()`
- Manual network toggle using `ManualNetworkMonitor`
- Simulated server responses — Success (200), Retry (503), Conflict (409)
- Human-readable activity log wired to `RelaySyncLogger` and `RelaySyncMetrics`
- All three non-success task outcomes in a single demo

```bash
cd examples/advanced_field_app
flutter pub get
flutter run
```

### `basic_dio_hive_app`

**Location:** `examples/basic_dio_hive_app/`  
**Stack:** `relay_sync` + `relay_sync_dio` + `relay_sync_hive` + `relay_sync_flutter`

Minimal production wiring demo. Demonstrates:

- `async main()` with `Hive.initFlutter()` — required before `HiveSyncStorage`
- Correct `StatefulWidget` lifecycle for initializing and disposing the full stack
- Tasks persisting in a Hive box across app restarts
- `DioSyncClient` configured with a base URL

```bash
cd examples/basic_dio_hive_app
flutter pub get
flutter run
```

---

## Running Tests

Each package has its own test suite. Run from the package root:

```bash
# Core
cd packages/relay_sync && dart test

# HTTP adapters
cd packages/relay_sync_dio  && dart test
cd packages/relay_sync_http && dart test

# Storage adapters
cd packages/relay_sync_hive    && dart test
cd packages/relay_sync_sqflite && dart test
cd packages/relay_sync_drift   && dart test

# Flutter package
cd packages/relay_sync_flutter && flutter test
```

Run all Dart-only packages in one shot:

```bash
for pkg in relay_sync relay_sync_dio relay_sync_http relay_sync_hive relay_sync_sqflite relay_sync_drift; do
  echo "=== $pkg ==="
  (cd packages/$pkg && dart test)
done
```

---

## Package Dependency Map

```
relay_sync            (pure Dart core — zero runtime dependencies)
    │
    ├── relay_sync_dio        + dio
    ├── relay_sync_http       + package:http
    ├── relay_sync_hive       + hive
    ├── relay_sync_sqflite    + sqflite + sqflite_common
    ├── relay_sync_drift      + drift
    └── relay_sync_flutter    + connectivity_plus + package:http + Flutter SDK
```

Each adapter adds only its own peer dependency. You include exactly what you need — unused adapters add zero code to your binary.

---

## Monorepo Commands

If you use [Melos](https://melos.invertase.dev/):

```bash
melos bootstrap    # link all packages
melos run analyze  # dart analyze across all packages
melos run test     # run all test suites
```

---

## Roadmap Ideas

- Push-notification-triggered sync (FCM / APNs wake-up)
- Background fetch integration for iOS / Android
- Configurable task TTL — auto-expire stale tasks
- Read-queue support (GET requests with response caching)
- pub.dev publishing with semantic versioning
