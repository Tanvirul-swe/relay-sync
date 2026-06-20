import 'package:relay_sync/relay_sync.dart';
import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory defaultDatabaseFactory() {
  throw const RelaySyncException(
    message: 'SqfliteSyncStorage requires a databaseFactory outside Flutter.',
  );
}
