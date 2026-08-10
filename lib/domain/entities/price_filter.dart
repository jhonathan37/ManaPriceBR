class PriceFilter {
  const PriceFilter({
    this.language = 'Português',
    this.condition = 'NM',
    this.foil = false,
  });

  final String language;
  final String condition;
  final bool foil;

  PriceFilter copyWith({
    String? language,
    String? condition,
    bool? foil,
  }) {
    return PriceFilter(
      language: language ?? this.language,
      condition: condition ?? this.condition,
      foil: foil ?? this.foil,
    );
  }
}
