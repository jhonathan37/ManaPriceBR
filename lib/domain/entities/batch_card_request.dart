class BatchCardRequest {
  const BatchCardRequest({
    required this.cardNames,
    required this.language,
    required this.condition,
    required this.foil,
  });

  final List<String> cardNames;
  final String language;
  final String condition;
  final bool foil;

  List<String> get normalizedNames => cardNames
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
