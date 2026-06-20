# relay_sync_http

package:http-based `SyncClient` adapter for `relay_sync`.

## Setup

```dart
import 'package:http/http.dart' as http;
import 'package:relay_sync_http/relay_sync_http.dart';

final client = HttpSyncClient(
  client: http.Client(),
  baseUri: Uri.parse('https://api.example.com'),
);
```

Relative task endpoints are resolved against `baseUri`. Absolute task URLs can be
used without a `baseUri`.

```dart
final response = await client.execute(
  task,
  headers: const <String, String>{
    'authorization': 'Bearer token',
  },
);
```

Close the underlying `package:http` client when it is no longer needed:

```dart
client.close();
```

## Behavior

- Supports GET, POST, PUT, PATCH, DELETE.
- Encodes POST, PUT, PATCH, and DELETE task bodies as JSON.
- Returns successful 2xx responses as `SyncResponse`.
- Maps HTTP failures to `SyncClientException` with the same categories as
  `relay_sync_dio`:
  - retryable: timeout/client errors and status `408`, `429`, `500`, `502`, `503`, `504`
  - permanent: `400`, `403`, `404`, `422`
  - unauthorized: `401`
  - conflict: `409`
