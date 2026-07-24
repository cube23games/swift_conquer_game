import 'dart:convert';

final class StateHasher {
  const StateHasher();

  int hashJson(Object? value) {
    final text = jsonEncode(value);
    var hash = 0x811c9dc5;
    for (final code in text.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
