# relay_sync_dio

Dio-based `SyncClient` adapter for `relay_sync`.

## Setup

```dart
import 'package:dio/dio.dart';
import 'package:relay_sync_dio/relay_sync_dio.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

final client = DioSyncClient(dio: dio);
```

## Behavior

- Uses Dio `baseUrl` when task endpoint is relative.
- Supports GET, POST, PUT, PATCH, DELETE.
- Maps `DioException` to `SyncClientException` with categories:
  - retryable: timeout/connection errors and status `408`, `429`, `500`, `502`, `503`, `504`
  - permanent: `400`, `403`, `404`, `422`
  - unauthorized: `401`
  - conflict: `409`
