import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:relay_sync/relay_sync.dart';

/// Performs connectivity checks with an optional internet health endpoint.
class InternetHealthCheckMonitor implements NetworkMonitor {
  /// Creates a monitor backed by `connectivity_plus`.
  ///
  /// If [healthUrl] or [pingUrl] is supplied, connectivity is considered
  /// reliable only when that URL returns a 2xx or 3xx response within [timeout].
  InternetHealthCheckMonitor({
    Connectivity? connectivity,
    Uri? healthUrl,
    Uri? pingUrl,
    Duration timeout = const Duration(seconds: 5),
    http.Client? httpClient,
    bool closeHttpClient = true,
  }) : this.custom(
          checkConnectivity: (connectivity ?? Connectivity()).checkConnectivity,
          onConnectivityChanged:
              (connectivity ?? Connectivity()).onConnectivityChanged,
          healthUrl: healthUrl ?? pingUrl,
          timeout: timeout,
          httpClient: httpClient,
          closeHttpClient: closeHttpClient,
        );

  /// Creates a monitor with injected connectivity and health-check behavior.
  ///
  /// This constructor is primarily useful for tests.
  InternetHealthCheckMonitor.custom({
    required Future<List<ConnectivityResult>> Function() checkConnectivity,
    required Stream<List<ConnectivityResult>> onConnectivityChanged,
    Uri? healthUrl,
    Duration timeout = const Duration(seconds: 5),
    http.Client? httpClient,
    Future<bool> Function(Uri url)? healthCheck,
    bool closeHttpClient = true,
  })  : _checkConnectivity = checkConnectivity,
        _onConnectivityChanged = onConnectivityChanged,
        _healthUrl = healthUrl,
        _timeout = timeout,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null && closeHttpClient,
        _healthCheck = healthCheck {
    _statusSubscription = _onConnectivityChanged
        .asyncMap(_isReliableForConnectivityResults)
        .distinct()
        .listen(_statusController.add, onError: (_) {
      _statusController.add(false);
    });
  }

  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _onConnectivityChanged;
  final Uri? _healthUrl;
  final Duration _timeout;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Future<bool> Function(Uri url)? _healthCheck;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _statusSubscription;
  bool _disposed = false;

  @override
  Stream<bool> get onStatusChanged {
    _ensureNotDisposed();
    return _statusController.stream;
  }

  @override
  Future<bool> get hasReliableConnection async {
    _ensureNotDisposed();
    try {
      return _isReliableForConnectivityResults(await _checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _statusSubscription.cancel();
    await _statusController.close();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<bool> _isReliableForConnectivityResults(
    List<ConnectivityResult> results,
  ) async {
    if (!_hasNetworkType(results)) {
      return false;
    }

    final healthUrl = _healthUrl;
    if (healthUrl == null) {
      return true;
    }

    try {
      final healthCheck = _healthCheck;
      if (healthCheck != null) {
        return await healthCheck(healthUrl).timeout(_timeout);
      }

      final response = await _httpClient.get(healthUrl).timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const RelaySyncException(
        message: 'InternetHealthCheckMonitor has been disposed.',
      );
    }
  }

  static bool _hasNetworkType(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
