import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_dio/relay_sync_dio.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';
import 'package:relay_sync_hive/relay_sync_hive.dart';

/// Hive must be initialized before the app starts.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Sync — Dio + Hive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
        useMaterial3: true,
      ),
      home: const SyncDemoScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class SyncDemoScreen extends StatefulWidget {
  const SyncDemoScreen({super.key});

  @override
  State<SyncDemoScreen> createState() => _SyncDemoScreenState();
}

class _SyncDemoScreenState extends State<SyncDemoScreen> {
  // --- relay_sync stack -------------------------------------------------------
  //
  // DioSyncClient  → real Dio HTTP client for sending sync requests.
  // HiveSyncStorage → persistent Hive box; tasks survive app restarts.
  // ManualNetworkMonitor → lets us toggle "online / offline" in the demo.
  // RelaySyncEngine → orchestrates the queue.
  // RelaySyncController → ergonomic API used by the UI.
  // RelaySyncFlutter → Flutter integration marker from relay_sync_flutter.
  //
  late final DioSyncClient _syncClient;
  late final HiveSyncStorage _storage;
  late final ManualNetworkMonitor _networkMonitor;
  late final RelaySyncEngine _engine;
  late final RelaySyncController _controller;
  final RelaySyncFlutter _flutterIntegration = const RelaySyncFlutter();

  // --- reactive state ---------------------------------------------------------
  List<SyncTask> _tasks = <SyncTask>[];
  Map<SyncTaskStatus, int> _counts = <SyncTaskStatus, int>{};
  RelaySyncState _engineState = RelaySyncState.idle;
  final List<_LogEntry> _log = <_LogEntry>[];

  StreamSubscription<List<SyncTask>>? _tasksSub;
  StreamSubscription<Map<SyncTaskStatus, int>>? _countsSub;
  StreamSubscription<RelaySyncState>? _stateSub;

  bool _isOnline = false;
  bool _isReady = false;
  bool _isBusy = false;
  String? _initError;

  // --- lifecycle --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initStack();
  }

  Future<void> _initStack() async {
    try {
      // Build the stack — order matters: storage must be initialized before
      // the engine starts using it.
      _syncClient = DioSyncClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.example.com')),
      );
      _storage = HiveSyncStorage(boxName: 'basic_dio_hive_demo');
      await _storage.initialize(); // opens the Hive box

      _networkMonitor = ManualNetworkMonitor(initiallyOnline: false);

      _engine = RelaySyncEngine(
        storage: _storage,
        client: _syncClient,
        networkMonitor: _networkMonitor,
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          syncOnNetworkRestore: false,
          deleteSyncedTasks: false,
          retryPolicy: ExponentialBackoffRetryPolicy(
            initialDelay: const Duration(seconds: 2),
            maxDelay: const Duration(minutes: 1),
          ),
          logger: _DemoLogger(addEntry: _addLog),
          metrics: _DemoMetrics(addEntry: _addLog),
        ),
      );

      _controller = RelaySyncController(engine: _engine);
      await _controller.initialize();

      // Subscribe to live updates from Hive.
      _tasksSub = _controller.watchTasks().listen((tasks) {
        if (!mounted) return;
        setState(() {
          _tasks = List<SyncTask>.of(tasks)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      });

      _countsSub = _controller.watchStatusCounts().listen((counts) {
        if (!mounted) return;
        setState(() => _counts = counts);
      });

      _stateSub = _controller.watchState().listen((state) {
        if (!mounted) return;
        setState(() => _engineState = state);
        _addLog('Engine → ${_stateLabel(state)}');
      });

      if (!mounted) return;
      setState(() => _isReady = true);
      _addLog('Stack ready. Hive box open. Device is offline.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _countsSub?.cancel();
    _stateSub?.cancel();
    unawaited(_controller.dispose());
    unawaited(_storage.close());
    super.dispose();
  }

  // --- actions ----------------------------------------------------------------

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, _LogEntry(message, DateTime.now()));
      if (_log.length > 20) _log.removeLast();
    });
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_isBusy || !_isReady) return;
    setState(() => _isBusy = true);
    try {
      await fn();
    } catch (e) {
      _addLog('Error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _queueSampleTask() => _run(() async {
        final task = await _controller.post(
          '/v1/items',
          body: <String, Object?>{
            'name': 'Item ${DateTime.now().millisecondsSinceEpoch % 1000}',
            'createdAt': DateTime.now().toIso8601String(),
          },
          priority: SyncPriority.normal,
          tags: const <String, String>{'source': 'basic_demo'},
        );
        _addLog('Queued task ${task.id.substring(0, 12)}… → ${task.endpoint}');
      });

  Future<void> _toggleNetwork(bool online) => _run(() async {
        setState(() => _isOnline = online);
        await _networkMonitor.setOnlineStatus(online);
        _addLog(online ? 'Network ON — ready to sync.' : 'Network OFF — tasks queue locally.');
      });

  Future<void> _syncNow() => _run(() async {
        if (!_isOnline) {
          _addLog('Cannot sync while offline — toggle network first.');
          return;
        }
        _addLog('Sync started…');
        await _controller.syncNow();
      });

  Future<void> _retryFailed() => _run(() async {
        await _controller.retryAllFailed();
        _addLog('Failed tasks reset to pending.');
      });

  Future<void> _clearAll() => _run(() async {
        await _storage.clearAll();
        _addLog('All tasks removed from Hive storage.');
      });

  int _count(SyncTaskStatus s) => _counts[s] ?? 0;

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Initialization failed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(_initError!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Dio + Hive Example'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatePill(state: _engineState),
          ),
        ],
      ),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: <Widget>[
                // ── Stack info ─────────────────────────────────────────────
                _InfoCard(
                  title: 'Package Stack',
                  icon: Icons.layers_outlined,
                  child: Column(
                    children: <Widget>[
                      _StackRow(
                        icon: Icons.http,
                        label: 'HTTP Client',
                        value: _syncClient.runtimeType.toString(),
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 8),
                      _StackRow(
                        icon: Icons.storage_outlined,
                        label: 'Storage',
                        value: _storage.runtimeType.toString(),
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(height: 8),
                      _StackRow(
                        icon: Icons.flutter_dash,
                        label: 'Flutter Integration',
                        value: _flutterIntegration.runtimeType.toString(),
                        color: Colors.teal.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Network toggle ─────────────────────────────────────────
                _InfoCard(
                  title: 'Network',
                  icon: _isOnline ? Icons.wifi : Icons.wifi_off,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _isOnline
                              ? 'Sync will attempt real Dio requests to the configured base URL.'
                              : 'All tasks are held in Hive until the network is enabled.',
                        ),
                        value: _isOnline,
                        onChanged: _isBusy ? null : _toggleNetwork,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Actions ────────────────────────────────────────────────
                _InfoCard(
                  title: 'Actions',
                  icon: Icons.play_circle_outline,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _queueSampleTask,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Queue Task'),
                      ),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _syncNow,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Now'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _retryFailed,
                        icon: const Icon(Icons.replay_outlined),
                        label: const Text('Retry Failed'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _clearAll,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Queue status ───────────────────────────────────────────
                _InfoCard(
                  title: 'Hive Queue  (${_tasks.length} task${_tasks.length == 1 ? '' : 's'})',
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _CountChip('Pending', _count(SyncTaskStatus.pending), Colors.blue),
                          _CountChip('Syncing', _count(SyncTaskStatus.syncing), Colors.purple),
                          _CountChip('Synced', _count(SyncTaskStatus.synced), Colors.green),
                          _CountChip('Retry', _count(SyncTaskStatus.retryScheduled), Colors.orange),
                          _CountChip('Failed', _count(SyncTaskStatus.failedPermanent), Colors.red),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.inbox_outlined),
                              SizedBox(width: 10),
                              Text('No tasks yet. Press "Queue Task" to add one.\n'
                                  'Tasks persist in Hive across app restarts.'),
                            ],
                          ),
                        )
                      else
                        ..._tasks.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TaskRow(task: t),
                            )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Activity log ───────────────────────────────────────────
                _InfoCard(
                  title: 'Activity Log',
                  icon: Icons.receipt_long_outlined,
                  child: _log.isEmpty
                      ? const Text('No activity yet.')
                      : Column(
                          children: _log.map((e) => _LogRow(entry: e)).toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  const _StackRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final RelaySyncState state;

  @override
  Widget build(BuildContext context) {
    final syncing = state == RelaySyncState.syncing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (syncing) ...<Widget>[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _stateLabel(state),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.count, this.color);

  final String label;
  final int count;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: active ? 0.12 : 0.05),
      side: BorderSide(color: color.withValues(alpha: active ? 0.5 : 0.2)),
      label: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: color.withValues(alpha: active ? 1.0 : 0.5),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final SyncTask task;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _statusStyle(task.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${task.method.name.toUpperCase()} ${task.endpoint}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          Text(
            task.id.substring(0, 10),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final h = entry.time.hour.toString().padLeft(2, '0');
    final m = entry.time.minute.toString().padLeft(2, '0');
    final s = entry.time.second.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$h:$m:$s',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _stateLabel(RelaySyncState state) => switch (state) {
      RelaySyncState.idle => 'Idle',
      RelaySyncState.syncing => 'Syncing…',
      RelaySyncState.paused => 'Paused',
      RelaySyncState.disposed => 'Disposed',
    };

(IconData, Color, String) _statusStyle(SyncTaskStatus s) => switch (s) {
      SyncTaskStatus.pending => (Icons.hourglass_empty_outlined, Colors.blue, 'Pending'),
      SyncTaskStatus.syncing => (Icons.sync, Colors.purple, 'Syncing'),
      SyncTaskStatus.synced => (Icons.check_circle_outline, Colors.green, 'Synced'),
      SyncTaskStatus.retryScheduled => (Icons.schedule_outlined, Colors.orange, 'Retry Scheduled'),
      SyncTaskStatus.failedRetryable =>
        (Icons.error_outline, Colors.deepOrange, 'Failed — will retry'),
      SyncTaskStatus.failedPermanent =>
        (Icons.cancel_outlined, Colors.red, 'Failed Permanently'),
      SyncTaskStatus.conflict => (Icons.warning_amber_outlined, Colors.red, 'Conflict'),
      SyncTaskStatus.cancelled => (Icons.block_outlined, Colors.grey, 'Cancelled'),
    };

// ---------------------------------------------------------------------------
// Log entry model
// ---------------------------------------------------------------------------

class _LogEntry {
  const _LogEntry(this.message, this.time);
  final String message;
  final DateTime time;
}

// ---------------------------------------------------------------------------
// Logger + Metrics
// ---------------------------------------------------------------------------

class _DemoLogger implements RelaySyncLogger {
  const _DemoLogger({required void Function(String) addEntry}) : _add = addEntry;

  final void Function(String) _add;

  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final prefix = switch (level) {
      RelaySyncLogLevel.debug => 'debug',
      RelaySyncLogLevel.info => 'info',
      RelaySyncLogLevel.warning => 'warn',
      RelaySyncLogLevel.error => 'error',
    };
    _add('[$prefix] $message${error != null ? ' — $error' : ''}');
  }
}

class _DemoMetrics implements RelaySyncMetrics {
  const _DemoMetrics({required void Function(String) addEntry}) : _add = addEntry;

  final void Function(String) _add;

  @override
  void increment(
    String name, {
    int value = 1,
    Map<String, String> tags = const <String, String>{},
  }) {
    _add('[metric] $name +$value');
  }

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, String> tags = const <String, String>{},
  }) {
    _add('[timing] $name: ${duration.inMilliseconds} ms');
  }
}
