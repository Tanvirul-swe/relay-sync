import 'dart:async';

import 'package:flutter/material.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';

void main() => runApp(const MyApp());

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Field Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
        useMaterial3: true,
      ),
      home: const FieldEditorScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo scenario enum
// ---------------------------------------------------------------------------

/// What the fake server returns when a sync task is sent.
enum _ServerBehavior {
  /// Server accepts the request — task moves to "Synced".
  success,

  /// Server is unavailable (HTTP 503) — task will be retried.
  serverError,

  /// Data conflict detected (HTTP 409) — task stops and waits for resolution.
  conflict,
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class FieldEditorScreen extends StatefulWidget {
  const FieldEditorScreen({super.key});

  @override
  State<FieldEditorScreen> createState() => _FieldEditorScreenState();
}

class _FieldEditorScreenState extends State<FieldEditorScreen> {
  // --- relay_sync objects -------------------------------------------------
  late final ManualNetworkMonitor _networkMonitor;
  late final InMemorySyncStorage _storage;
  late final _DemoSyncClient _client;
  late final RelaySyncEngine _engine;
  late final RelaySyncController _controller;

  // ignore: unused_field — kept to show the flutter integration is wired in
  final RelaySyncFlutter _flutterIntegration = const RelaySyncFlutter();

  // --- form state ---------------------------------------------------------
  late final TextEditingController _fieldController;
  String _lastSyncedValue = 'Hello from the server!';

  // --- demo controls ------------------------------------------------------
  bool _isOnline = false;
  _ServerBehavior _serverBehavior = _ServerBehavior.success;

  // --- reactive state from relay_sync -------------------------------------
  List<SyncTask> _tasks = <SyncTask>[];
  Map<SyncTaskStatus, int> _counts = <SyncTaskStatus, int>{};
  RelaySyncState _engineState = RelaySyncState.idle;
  final List<_LogEntry> _log = <_LogEntry>[];

  StreamSubscription<List<SyncTask>>? _tasksSub;
  StreamSubscription<Map<SyncTaskStatus, int>>? _countsSub;
  StreamSubscription<RelaySyncState>? _stateSub;

  bool _isReady = false;
  bool _isBusy = false;

  // --- lifecycle ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fieldController = TextEditingController(text: _lastSyncedValue);
    _networkMonitor = ManualNetworkMonitor(initiallyOnline: false);
    _storage = InMemorySyncStorage();
    _client = _DemoSyncClient(
      getServerBehavior: () => _serverBehavior,
      onSynced: _onServerAccepted,
    );
    _engine = RelaySyncEngine(
      storage: _storage,
      client: _client,
      networkMonitor: _networkMonitor,
      config: RelaySyncConfig(
        autoSync: false,
        syncOnStart: false,
        syncOnNetworkRestore: false,
        deleteSyncedTasks: false,
        retryPolicy: FixedRetryPolicy(delay: const Duration(seconds: 5)),
        logger: _DemoLogger(addEntry: _addLog),
        metrics: _DemoMetrics(addEntry: _addLog),
      ),
    );
    _controller = RelaySyncController(engine: _engine);
    _setup();
  }

  Future<void> _setup() async {
    await _controller.initialize();

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
      _addLog('Sync engine is now ${_engineStateLabel(state)}.');
    });

    if (!mounted) return;
    setState(() => _isReady = true);
    _addLog('App ready. Device is offline — edits will be queued locally.');
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _countsSub?.cancel();
    _stateSub?.cancel();
    _fieldController.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  // --- helpers ------------------------------------------------------------

  void _onServerAccepted(String value) {
    if (!mounted) return;
    setState(() => _lastSyncedValue = value);
    _addLog('Server accepted the change. Synced value: "$value"');
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, _LogEntry(message, DateTime.now()));
      if (_log.length > 25) _log.removeLast();
    });
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_isBusy || !_isReady) return;
    setState(() => _isBusy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // --- user actions -------------------------------------------------------

  Future<void> _saveEdit() => _run(() async {
        final text = _fieldController.text.trim();
        if (text.isEmpty) return;
        final task = await _controller.patch(
          '/api/notes/1',
          body: <String, Object?>{'value': text},
          priority: SyncPriority.high,
          dedupeKey: 'note-1',
          tags: const <String, String>{'screen': 'field_editor'},
        );
        _addLog(
          'Edit saved locally. '
          'Task ${task.id.substring(0, 10)}… is pending sync.',
        );
      });

  Future<void> _toggleNetwork(bool online) => _run(() async {
        setState(() => _isOnline = online);
        await _networkMonitor.setOnlineStatus(online);
        _addLog(online
            ? 'Network connected. Ready to sync.'
            : 'Network disconnected. Edits will queue locally.');
      });

  Future<void> _syncNow() => _run(() async {
        if (!_isOnline) {
          _addLog('Cannot sync while offline. Enable the network first.');
          return;
        }
        _addLog('Sync started…');
        await _controller.syncNow();
      });

  Future<void> _retryFailed() => _run(() async {
        await _controller.retryAllFailed();
        _addLog('Failed tasks reset to pending — they will retry on the next sync.');
      });

  Future<void> _clearSynced() => _run(() async {
        await _controller.clearSynced();
        _addLog('Cleared synced tasks from the queue.');
      });

  Future<void> _resetDemo() => _run(() async {
        await _storage.clearAll();
        await _networkMonitor.setOnlineStatus(false);
        const baseline = 'Hello from the server!';
        setState(() {
          _isOnline = false;
          _serverBehavior = _ServerBehavior.success;
          _lastSyncedValue = baseline;
          _fieldController.text = baseline;
          _log.clear();
        });
        _addLog('Demo reset. Device is offline again.');
      });

  // --- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Offline Field Editor'),
        centerTitle: false,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _EngineStatePill(state: _engineState),
          ),
        ],
      ),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: <Widget>[
                // ── Connection banner ──────────────────────────────────────
                _ConnectionBanner(isOnline: _isOnline),
                const SizedBox(height: 20),

                // ── Step 1: Edit ───────────────────────────────────────────
                _StepCard(
                  step: '1',
                  icon: Icons.edit_outlined,
                  title: 'Edit the field',
                  subtitle:
                      'Change the value below and press Save. Your edit is '
                      'stored locally even when you are offline.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: _fieldController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          labelText: 'Field value',
                          helperText:
                              'Last value accepted by server: "$_lastSyncedValue"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _saveEdit,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save  (adds to sync queue)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 2: Configure conditions ──────────────────────────
                _StepCard(
                  step: '2',
                  icon: Icons.tune_outlined,
                  title: 'Set the conditions',
                  subtitle:
                      'Toggle the network and choose how the fake server '
                      'should respond. This lets you explore every sync path.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          _isOnline ? Icons.wifi : Icons.wifi_off,
                          color: _isOnline ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _isOnline
                              ? 'Sync requests will reach the server.'
                              : 'Tasks pile up in the queue — nothing leaves the device.',
                        ),
                        value: _isOnline,
                        onChanged: _isBusy ? null : _toggleNetwork,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fake server response',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<_ServerBehavior>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<_ServerBehavior>>[
                          ButtonSegment<_ServerBehavior>(
                            value: _ServerBehavior.success,
                            icon: Icon(Icons.check_circle_outline),
                            label: Text('Success'),
                          ),
                          ButtonSegment<_ServerBehavior>(
                            value: _ServerBehavior.serverError,
                            icon: Icon(Icons.sync_problem_outlined),
                            label: Text('503 Error'),
                          ),
                          ButtonSegment<_ServerBehavior>(
                            value: _ServerBehavior.conflict,
                            icon: Icon(Icons.warning_amber_outlined),
                            label: Text('409 Conflict'),
                          ),
                        ],
                        selected: <_ServerBehavior>{_serverBehavior},
                        onSelectionChanged: _isBusy
                            ? null
                            : (Set<_ServerBehavior> s) {
                                setState(() => _serverBehavior = s.first);
                                _addLog(
                                    'Server response set to: ${_behaviorLabel(s.first)}');
                              },
                      ),
                      const SizedBox(height: 12),
                      _ServerBehaviorHint(behavior: _serverBehavior),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 3: Trigger sync ───────────────────────────────────
                _StepCard(
                  step: '3',
                  icon: Icons.sync,
                  title: 'Run the sync',
                  subtitle:
                      'Go online (Step 2), then press Sync Now. '
                      'Watch the queue update in real time below.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
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
                        onPressed: _isBusy ? null : _clearSynced,
                        icon: const Icon(Icons.playlist_remove_outlined),
                        label: const Text('Clear Synced'),
                      ),
                      TextButton.icon(
                        onPressed: _isBusy ? null : _resetDemo,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Demo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 4: Queue ──────────────────────────────────────────
                _StepCard(
                  step: '4',
                  icon: Icons.list_alt_outlined,
                  title: 'Sync queue',
                  subtitle:
                      'Every saved edit becomes one task in the queue. '
                      'Tasks move through states as relay_sync processes them.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _StatusSummaryRow(counts: _counts),
                      const SizedBox(height: 14),
                      if (_tasks.isEmpty)
                        _EmptyQueueMessage()
                      else
                        ..._tasks.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TaskCard(task: t),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 5: Activity log ───────────────────────────────────
                _StepCard(
                  step: '5',
                  icon: Icons.receipt_long_outlined,
                  title: 'Activity log',
                  subtitle:
                      'Human-readable events from the sync engine, '
                      'logger, and metrics hooks.',
                  child: _log.isEmpty
                      ? const Text(
                          'No events yet. Save an edit in Step 1 to begin.')
                      : Column(
                          children: _log
                              .map((e) => _LogRow(entry: e))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// UI helper widgets
// ---------------------------------------------------------------------------

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label, sub) = isOnline
        ? (
            Colors.green.shade700,
            Icons.wifi,
            'Online',
            'Sync can reach the server.',
          )
        : (
            Colors.orange.shade800,
            Icons.wifi_off,
            'Offline',
            'Edits are queued on-device until you reconnect.',
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              Text(sub,
                  style: TextStyle(color: color.withValues(alpha: 0.85))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngineStatePill extends StatelessWidget {
  const _EngineStatePill({required this.state});

  final RelaySyncState state;

  @override
  Widget build(BuildContext context) {
    final isSyncing = state == RelaySyncState.syncing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSyncing
            ? Colors.blue.shade100
            : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isSyncing) ...<Widget>[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _engineStateLabel(state),
            style: TextStyle(
              fontSize: 12,
              color: isSyncing
                  ? Colors.blue.shade800
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String step;
  final IconData icon;
  final String title;
  final String subtitle;
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
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ServerBehaviorHint extends StatelessWidget {
  const _ServerBehaviorHint({required this.behavior});

  final _ServerBehavior behavior;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (behavior) {
      _ServerBehavior.success => (
          Icons.check_circle_outline,
          Colors.green.shade700,
          'The server returns 200 OK. The task moves to "Synced" ✓',
        ),
      _ServerBehavior.serverError => (
          Icons.sync_problem_outlined,
          Colors.orange.shade800,
          'The server returns 503. The task moves to "Retry Scheduled" '
              'and will automatically retry after a delay.',
        ),
      _ServerBehavior.conflict => (
          Icons.warning_amber_outlined,
          Colors.red.shade700,
          'The server returns 409. The task moves to "Conflict" and '
              'waits for manual resolution.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryRow extends StatelessWidget {
  const _StatusSummaryRow({required this.counts});

  final Map<SyncTaskStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final chips = <(String label, Color color, SyncTaskStatus status)>[
      ('Pending', Colors.blue.shade700, SyncTaskStatus.pending),
      ('Syncing', Colors.purple.shade700, SyncTaskStatus.syncing),
      ('Synced ✓', Colors.green.shade700, SyncTaskStatus.synced),
      ('Retry', Colors.orange.shade800, SyncTaskStatus.retryScheduled),
      ('Conflict', Colors.red.shade700, SyncTaskStatus.conflict),
      ('Failed', Colors.red.shade900, SyncTaskStatus.failedPermanent),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        final n = counts[c.$3] ?? 0;
        return Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor: c.$2.withValues(alpha: n > 0 ? 0.12 : 0.05),
          side: BorderSide(color: c.$2.withValues(alpha: n > 0 ? 0.5 : 0.2)),
          label: Text(
            '${c.$1}: $n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: n > 0 ? FontWeight.bold : FontWeight.normal,
              color: c.$2.withValues(alpha: n > 0 ? 1.0 : 0.45),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyQueueMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Queue is empty.\nSave an edit in Step 1 to add your first task.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final SyncTask task;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _taskStatusStyle(task.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.method.name.toUpperCase()}  ${task.endpoint}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (task.body.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Payload: ${task.body}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      'Attempt ${task.retryCount}/${task.maxRetries}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (task.nextRetryAt != null) ...<Widget>[
                      const Text('  ·  '),
                      Text(
                        'Retry at ${_formatTime(task.nextRetryAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (task.lastError != null) ...<Widget>[
                      const Text('  ·  '),
                      Flexible(
                        child: Text(
                          task.lastError!.message,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _formatTime(entry.time),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.message)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Utility functions
// ---------------------------------------------------------------------------

String _engineStateLabel(RelaySyncState state) => switch (state) {
      RelaySyncState.idle => 'Idle',
      RelaySyncState.syncing => 'Syncing…',
      RelaySyncState.paused => 'Paused',
      RelaySyncState.disposed => 'Disposed',
    };

String _behaviorLabel(_ServerBehavior b) => switch (b) {
      _ServerBehavior.success => '200 Success',
      _ServerBehavior.serverError => '503 Server Error',
      _ServerBehavior.conflict => '409 Conflict',
    };

(IconData, Color, String) _taskStatusStyle(SyncTaskStatus status) =>
    switch (status) {
      SyncTaskStatus.pending => (
          Icons.hourglass_empty_outlined,
          Colors.blue.shade700,
          'Pending',
        ),
      SyncTaskStatus.syncing => (
          Icons.sync,
          Colors.purple.shade700,
          'Syncing',
        ),
      SyncTaskStatus.synced => (
          Icons.check_circle_outline,
          Colors.green.shade700,
          'Synced',
        ),
      SyncTaskStatus.retryScheduled => (
          Icons.schedule_outlined,
          Colors.orange.shade800,
          'Retry Scheduled',
        ),
      SyncTaskStatus.failedRetryable => (
          Icons.error_outline,
          Colors.orange.shade900,
          'Failed (retryable)',
        ),
      SyncTaskStatus.failedPermanent => (
          Icons.cancel_outlined,
          Colors.red.shade900,
          'Failed Permanently',
        ),
      SyncTaskStatus.conflict => (
          Icons.warning_amber_outlined,
          Colors.red.shade700,
          'Conflict',
        ),
      SyncTaskStatus.cancelled => (
          Icons.block_outlined,
          Colors.grey.shade600,
          'Cancelled',
        ),
    };

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

// ---------------------------------------------------------------------------
// Demo support — log entry model
// ---------------------------------------------------------------------------

class _LogEntry {
  const _LogEntry(this.message, this.time);
  final String message;
  final DateTime time;
}

// ---------------------------------------------------------------------------
// Demo support — fake HTTP client
// ---------------------------------------------------------------------------

class _DemoSyncClient implements SyncClient {
  _DemoSyncClient({
    required _ServerBehavior Function() getServerBehavior,
    required void Function(String value) onSynced,
  })  : _getServerBehavior = getServerBehavior,
        _onSynced = onSynced;

  final _ServerBehavior Function() _getServerBehavior;
  final void Function(String value) _onSynced;

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    // Simulate a 400 ms round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return switch (_getServerBehavior()) {
      _ServerBehavior.success => () {
          final value = task.body['value']?.toString() ?? '';
          _onSynced(value);
          return SyncResponse(
            statusCode: 200,
            body: <String, Object?>{'ok': true, 'value': value},
          );
        }(),
      _ServerBehavior.serverError => const SyncResponse(
          statusCode: 503,
          body: <String, Object?>{'error': 'Service temporarily unavailable.'},
        ),
      _ServerBehavior.conflict => const SyncResponse(
          statusCode: 409,
          body: <String, Object?>{'error': 'Field was updated by another device.'},
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Demo support — logger + metrics
// ---------------------------------------------------------------------------

class _DemoLogger implements RelaySyncLogger {
  const _DemoLogger({required void Function(String) addEntry})
      : _add = addEntry;

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
  const _DemoMetrics({required void Function(String) addEntry})
      : _add = addEntry;

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
