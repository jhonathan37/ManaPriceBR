class CardNameParser {
  const CardNameParser._();

  static String clean(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return '';

    final ignored = RegExp(
      r'^(magic|the gathering|wizards|legendary|creature|instant|sorcery|artifact|enchantment|planeswalker|basic land|land)$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final normalized = line
          .replaceAll(RegExp(r'[^\p{L}\p{N}\'\- ]', unicode: true), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (normalized.length >= 3 && !ignored.hasMatch(normalized)) {
        return normalized;
      }
    }

    return lines.first;
  }
}
