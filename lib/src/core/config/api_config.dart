final class ApiConfig {
  const ApiConfig._();

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('API endpoint cannot be empty.');
    }

    final withScheme = trimmed.startsWith('http://') ||
            trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    return withScheme.replaceFirst(RegExp(r'/+$'), '');
  }
}
