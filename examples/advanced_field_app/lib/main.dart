import 'dart:async';

import 'package:flutter/material.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';

void main() {
  runApp(const MyApp());
}

enum DemoServerMode { success, retryableError, conflict }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Field Sync Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14532D)),
        useMaterial3: true,
      ),
      home: const AdvancedFieldSyncDemo(),
    );
  }
}

class AdvancedFieldSyncDemo extends StatefulWidget {
  const AdvancedFieldSyncDemo({super.key});

  @override
  State<AdvancedFieldSyncDemo> createState() => _AdvancedFieldSyncDemoState();
}

class _AdvancedFieldSyncDemoState extends State<AdvancedFieldSyncDemo> {
  late final TextEditingController _draftController;
  late final DemoAppLogger _logger;
  late final DemoAppMetrics _metrics;
  late final ManualNetworkMonitor _networkMonitor;
  late final InMemorySyncStorage _storage;
  late final DemoSyncClient _syncClient;
  late final RelaySyncEngine _engine;
  late final RelaySyncController _controller;
  late final RelaySyncFlutter _flutterIntegration;

  StreamSubscription<List<SyncTask>>? _tasksSubscription;
  StreamSubscription<Map<SyncTaskStatus, int>>? _countsSubscription;
  StreamSubscription<RelaySyncState>? _stateSubscription;

  List<SyncTask> _tasks = <SyncTask>[];
  Map<SyncTaskStatus, int> _counts = <SyncTaskStatus, int>{};
  List<String> _timeline = <String>[];
  RelaySyncState _engineState = RelaySyncState.idle;
  DemoServerMode _serverMode = DemoServerMode.success;
  bool _isOnline = false;
  bool _isReady = false;
  bool _isWorking = false;
  int _draftVersion = 1;
  String _remoteValue = 'Baseline note from server';
  String _lastSyncedValue = 'Baseline note from server';
  String? _lastQueuedTaskId;

  @override
  void initState() {
    super.initState();
    _draftController = TextEditingController(text: _lastSyncedValue);
    _logger = DemoAppLogger(onEntry: _addTimelineEntry);
    _metrics = DemoAppMetrics(onEntry: _addTimelineEntry);
    _networkMonitor = ManualNetworkMonitor(initiallyOnline: false);
    _storage = InMemorySyncStorage();
    _syncClient = DemoSyncClient(
      onReadServerMode: () => _serverMode,
      onServerValueSynced: (value) {
        if (!mounted) {
          return;
        }
        setState(() {
          _remoteValue = value;
          _lastSyncedValue = value;
        });
      },
    );
    _engine = RelaySyncEngine(
      storage: _storage,
      client: _syncClient,
      networkMonitor: _networkMonitor,
      config: RelaySyncConfig(
        autoSync: false,
        syncOnStart: false,
        syncOnNetworkRestore: false,
        deleteSyncedTasks: false,
        retryPolicy: FixedRetryPolicy(delay: const Duration(seconds: 5)),
        logger: _logger,
        metrics: _metrics,
      ),
    );
    _controller = RelaySyncController(engine: _engine);
    _flutterIntegration = const RelaySyncFlutter();
    unawaited(_initializeDemo());
  }

  @override
  void dispose() {
    unawaited(_tasksSubscription?.cancel());
    unawaited(_countsSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    _draftController.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _initializeDemo() async {
    await _controller.initialize();

    _tasksSubscription = _controller.watchTasks().listen((tasks) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = List<SyncTask>.from(tasks)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });
    });

    _countsSubscription = _controller.watchStatusCounts().listen((counts) {
      if (!mounted) {
        return;
      }
      setState(() {
        _counts = counts;
      });
    });

    _stateSubscription = _controller.watchState().listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _engineState = state;
      });
      _addTimelineEntry('Engine state -> ${state.name}');
    });

    _addTimelineEntry('Advanced field sync demo initialized');
    _addTimelineEntry('relay_sync_flutter available as ${_flutterIntegration.runtimeType}');

    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = true;
    });
  }

  void _addTimelineEntry(String message) {
    if (!mounted) {
      return;
    }
    final timestamp = TimeOfDay.fromDateTime(DateTime.now()).format(context);
    setState(() {
      _timeline = <String>['$timestamp  $message', ..._timeline].take(18).toList(growable: false);
    });
  }

  Future<void> _setOnline(bool value) async {
    setState(() {
      _isOnline = value;
    });
    await _networkMonitor.setOnlineStatus(value);
    _addTimelineEntry(value ? 'Device is online' : 'Device is offline');
  }

  Future<void> _queueDraft() async {
    await _runAction(() async {
      final task = await _controller.patch(
        '/v1/field/42',
        body: <String, Object?>{
          'fieldId': '42',
          'value': _draftController.text,
          'version': _draftVersion,
        },
        priority: SyncPriority.high,
        dedupeKey: 'field-42',
        tags: const <String, String>{'screen': 'advanced_field_app'},
      );

      setState(() {
        _lastQueuedTaskId = task.id;
        _draftVersion += 1;
      });
      _addTimelineEntry('Queued PATCH task ${task.id} for field 42');
    });
  }

  Future<void> _syncNow() async {
    await _runAction(() async {
      await _controller.syncNow();
      _addTimelineEntry('Manual sync requested');
    });
  }

  Future<void> _retryFailed() async {
    await _runAction(() async {
      await _controller.retryAllFailed();
      _addTimelineEntry('Failed tasks moved back to pending');
    });
  }

  Future<void> _clearSynced() async {
    await _runAction(() async {
      await _controller.clearSynced();
      _addTimelineEntry('Synced tasks cleared from storage');
    });
  }

  Future<void> _resetDemo() async {
    await _runAction(() async {
      await _storage.clearAll();
      await _setOnline(false);
      setState(() {
        _serverMode = DemoServerMode.success;
        _draftVersion = 1;
        _lastQueuedTaskId = null;
        _remoteValue = 'Baseline note from server';
        _lastSyncedValue = 'Baseline note from server';
        _draftController.text = 'Baseline note from server';
        _timeline = <String>[];
      });
      _addTimelineEntry('Demo reset to baseline');
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isWorking || !_isReady) {
      return;
    }
    setState(() {
      _isWorking = true;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  int _countFor(SyncTaskStatus status) => _counts[status] ?? 0;

  Color _statusColor(BuildContext context, SyncTaskStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case SyncTaskStatus.pending:
        return scheme.secondaryContainer;
      case SyncTaskStatus.syncing:
        return scheme.primaryContainer;
      case SyncTaskStatus.retryScheduled:
      case SyncTaskStatus.failedRetryable:
        return Colors.orange.shade100;
      case SyncTaskStatus.synced:
        return Colors.green.shade100;
      case SyncTaskStatus.failedPermanent:
      case SyncTaskStatus.conflict:
        return Colors.red.shade100;
      case SyncTaskStatus.cancelled:
        return Colors.grey.shade300;
    }
  }

  String _serverModeDescription(DemoServerMode mode) {
    switch (mode) {
      case DemoServerMode.success:
        return 'Server accepts the request and marks the task as synced.';
      case DemoServerMode.retryableError:
        return 'Server returns HTTP 503 so the task moves to retryScheduled.';
      case DemoServerMode.conflict:
        return 'Server returns HTTP 409 so the task stops in conflict.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Field Sync Example'),
      ),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('Understand the offline sync flow', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'This example simulates a field-edit screen using relay_sync. '
                  'Edit the local draft, queue a PATCH request, choose what the server should do, '
                  'then toggle network and run sync to watch task states change.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _InfoCard(
                      label: 'Engine state',
                      value: _engineState.name,
                      hint: 'Lifecycle of RelaySyncEngine',
                    ),
                    _InfoCard(
                      label: 'Network',
                      value: _isOnline ? 'online' : 'offline',
                      hint: 'ManualNetworkMonitor toggle',
                    ),
                    _InfoCard(
                      label: 'Remote value',
                      value: _remoteValue,
                      hint: 'Fake server state',
                    ),
                    _InfoCard(
                      label: 'Last queued task',
                      value: _lastQueuedTaskId ?? 'none yet',
                      hint: 'Most recent PATCH request',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: '1. Edit Local Draft',
                  subtitle: 'The text below is your local form state before anything is synced.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _draftController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Field value',
                          helperText: 'Change this, then press Queue Draft Update.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isWorking ? null : _queueDraft,
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text('Queue Draft Update'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '2. Choose Sync Conditions',
                  subtitle: 'Use these controls to simulate the real-world conditions your users hit.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Device network is online'),
                        subtitle: const Text('When offline, syncNow exits before sending requests.'),
                        value: _isOnline,
                        onChanged: _isWorking ? null : _setOnline,
                      ),
                      const SizedBox(height: 8),
                      Text('Fake server response', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<DemoServerMode>(
                        segments: const <ButtonSegment<DemoServerMode>>[
                          ButtonSegment<DemoServerMode>(
                            value: DemoServerMode.success,
                            label: Text('Success'),
                          ),
                          ButtonSegment<DemoServerMode>(
                            value: DemoServerMode.retryableError,
                            label: Text('503 Retry'),
                          ),
                          ButtonSegment<DemoServerMode>(
                            value: DemoServerMode.conflict,
                            label: Text('409 Conflict'),
                          ),
                        ],
                        selected: <DemoServerMode>{_serverMode},
                        onSelectionChanged: _isWorking
                            ? null
                            : (selection) {
                                final mode = selection.first;
                                setState(() {
                                  _serverMode = mode;
                                });
                                _addTimelineEntry('Server mode -> ${mode.name}');
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(_serverModeDescription(_serverMode)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '3. Run The Sync Cycle',
                  subtitle: 'These actions map directly to the controller methods in relay_sync.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isWorking ? null : _syncNow,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Now'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isWorking ? null : _retryFailed,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Failed'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isWorking ? null : _clearSynced,
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Clear Synced'),
                      ),
                      TextButton.icon(
                        onPressed: _isWorking ? null : _resetDemo,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Demo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '4. Observe Queue State',
                  subtitle: 'The cards and task list below update from storage/watch streams.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _CountChip(label: 'pending', count: _countFor(SyncTaskStatus.pending)),
                          _CountChip(label: 'syncing', count: _countFor(SyncTaskStatus.syncing)),
                          _CountChip(label: 'retry', count: _countFor(SyncTaskStatus.retryScheduled)),
                          _CountChip(label: 'synced', count: _countFor(SyncTaskStatus.synced)),
                          _CountChip(label: 'conflict', count: _countFor(SyncTaskStatus.conflict)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_tasks.isEmpty)
                        const Text('No tasks yet. Queue a draft update to begin.')
                      else
                        ..._tasks.map(
                          (task) => Card(
                            color: _statusColor(context, task.status),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('${task.method.name.toUpperCase()} ${task.endpoint}'),
                              subtitle: Text(
                                'status=${task.status.name} retryCount=${task.retryCount} '
                                'nextRetryAt=${task.nextRetryAt?.toIso8601String() ?? 'none'}',
                              ),
                              trailing: Text(task.priority.name),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '5. Event Timeline',
                  subtitle: 'Logger and metrics hooks make the internal flow visible.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'relay_sync_flutter package: ${_flutterIntegration.runtimeType}\n'
                        'Retry policy: ${_engine.config.retryPolicy.runtimeType}',
                      ),
                      const SizedBox(height: 12),
                      if (_timeline.isEmpty)
                        const Text('No events yet.')
                      else
                        ..._timeline.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(entry),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(hint),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
    );
  }
}

class DemoSyncClient implements SyncClient {
  DemoSyncClient({
    required DemoServerMode Function() onReadServerMode,
    required void Function(String value) onServerValueSynced,
  })  : _onReadServerMode = onReadServerMode,
        _onServerValueSynced = onServerValueSynced;

  final DemoServerMode Function() _onReadServerMode;
  final void Function(String value) _onServerValueSynced;

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    switch (_onReadServerMode()) {
      case DemoServerMode.success:
        final value = task.body['value']?.toString() ?? '';
        _onServerValueSynced(value);
        return SyncResponse(
          statusCode: 200,
          body: <String, Object?>{
            'ok': true,
            'taskId': task.id,
            'value': value,
          },
        );
      case DemoServerMode.retryableError:
        return const SyncResponse(
          statusCode: 503,
          body: <String, Object?>{'message': 'Server unavailable'},
        );
      case DemoServerMode.conflict:
        return const SyncResponse(
          statusCode: 409,
          body: <String, Object?>{'message': 'Field has been updated elsewhere'},
        );
    }
  }
}

class DemoAppLogger implements RelaySyncLogger {
  DemoAppLogger({required void Function(String entry) onEntry}) : _onEntry = onEntry;

  final void Function(String entry) _onEntry;

  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final contextSummary = context.isEmpty ? '' : ' ${context.toString()}';
    _onEntry('log/${level.name}: $message$contextSummary');
    if (error != null) {
      _onEntry('log/${level.name}: error=$error');
    }
  }
}

class DemoAppMetrics implements RelaySyncMetrics {
  DemoAppMetrics({required void Function(String entry) onEntry}) : _onEntry = onEntry;

  final void Function(String entry) _onEntry;

  @override
  void increment(
    String name, {
    int value = 1,
    Map<String, String> tags = const <String, String>{},
  }) {
    _onEntry('metric: $name +$value');
  }

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, String> tags = const <String, String>{},
  }) {
    _onEntry('timing: $name ${duration.inMilliseconds}ms');
  }
}
