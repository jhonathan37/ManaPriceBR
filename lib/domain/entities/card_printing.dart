class CardPrinting {
  const CardPrinting({
    required this.name,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.imageUrl,
    required this.foilAvailable,
    required this.nonfoilAvailable,
  });

  final String name;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final String? imageUrl;
  final bool foilAvailable;
  final bool nonfoilAvailable;

  String get label => '$setName ($setCode) • #$collectorNumber';

  String get id => '${setCode.toLowerCase()}:$collectorNumber';
}
