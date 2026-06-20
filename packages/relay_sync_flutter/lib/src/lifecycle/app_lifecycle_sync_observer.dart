import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:relay_sync/relay_sync.dart';

/// Callback used when app lifecycle changes should trigger sync.
typedef AppLifecycleSyncCallback = Future<void> Function();

/// Observes Flutter app lifecycle changes and syncs when the app resumes.
class AppLifecycleSyncObserver with WidgetsBindingObserver {
  /// Creates an observer that calls [onResume] for resumed lifecycle events.
  AppLifecycleSyncObserver({
    required AppLifecycleSyncCallback onResume,
    WidgetsBinding? binding,
    bool registerImmediately = true,
  })  : _onResume = onResume,
        _binding = binding {
    if (registerImmediately) {
      register();
    }
  }

  /// Creates an observer that calls [RelaySyncController.syncNow] on resume.
  factory AppLifecycleSyncObserver.forController({
    required RelaySyncController controller,
    WidgetsBinding? binding,
    bool registerImmediately = true,
  }) {
    return AppLifecycleSyncObserver(
      onResume: controller.syncNow,
      binding: binding,
      registerImmediately: registerImmediately,
    );
  }

  final AppLifecycleSyncCallback _onResume;
  final WidgetsBinding? _binding;

  bool _registered = false;
  bool _syncInFlight = false;

  /// Registers this observer with the Flutter binding.
  void register() {
    if (_registered) {
      return;
    }
    (_binding ?? WidgetsBinding.instance).addObserver(this);
    _registered = true;
  }

  /// Unregisters this observer from the Flutter binding.
  void dispose() {
    if (!_registered) {
      return;
    }
    (_binding ?? WidgetsBinding.instance).removeObserver(this);
    _registered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _syncInFlight) {
      return;
    }

    _syncInFlight = true;
    unawaited(
      _onResume().whenComplete(() {
        _syncInFlight = false;
      }),
    );
  }
}
