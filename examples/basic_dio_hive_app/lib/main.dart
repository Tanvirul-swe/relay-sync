import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_dio/relay_sync_dio.dart';
import 'package:relay_sync_flutter/relay_sync_flutter.dart';
import 'package:relay_sync_hive/relay_sync_hive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleTask = SyncTask.post(
      id: 'example-task',
      endpoint: '/v1/items',
      metadata: SyncMetadata(taskId: 'example-task', method: SyncMethod.post),
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );
    final syncClient = DioSyncClient(dio: Dio());
    final storage = HiveSyncStorage();
    final flutterIntegration = RelaySyncFlutter();

    return MaterialApp(
      title: 'Basic Dio Hive Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
      ),
      home: ExampleHome(
        title: 'Basic Dio + Hive Example',
        sampleTask: sampleTask,
        syncClientType: syncClient.runtimeType.toString(),
        storageType: storage.runtimeType.toString(),
        flutterIntegrationType: flutterIntegration.runtimeType.toString(),
      ),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({
    super.key,
    required this.title,
    required this.sampleTask,
    required this.syncClientType,
    required this.storageType,
    required this.flutterIntegrationType,
  });

  final String title;
  final SyncTask sampleTask;
  final String syncClientType;
  final String storageType;
  final String flutterIntegrationType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Monorepo wiring ready', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text('Task id: ${sampleTask.id}'),
          Text('Method: ${sampleTask.method.name.toUpperCase()}'),
          Text('Endpoint: ${sampleTask.endpoint}'),
          const SizedBox(height: 16),
          Text('Client: $syncClientType'),
          Text('Storage: $storageType'),
          Text('Flutter package: $flutterIntegrationType'),
        ],
      ),
    );
  }
}
