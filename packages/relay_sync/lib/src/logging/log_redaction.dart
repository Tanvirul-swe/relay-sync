/// Utilities for redacting sensitive values from logs.
final class LogRedaction {
  static const Set<String> _sensitiveHeaderNames = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  /// Returns a copy of [headers] where sensitive values are replaced.
  static Map<String, String> redactHeaders(Map<String, String> headers) {
    final redacted = <String, String>{};
    headers.forEach((key, value) {
      final normalized = key.toLowerCase();
      redacted[key] = _sensitiveHeaderNames.contains(normalized) ? '<redacted>' : value;
    });
    return redacted;
  }
}
