import '../models/sync_response.dart';
import '../models/sync_task.dart';

/// Client abstraction used by [RelaySyncEngine] to execute sync tasks.
abstract interface class SyncClient {
  /// Executes [task] and returns a response.
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  });
}
