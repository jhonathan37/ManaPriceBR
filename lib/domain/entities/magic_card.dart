import 'package:equatable/equatable.dart';

class MagicCard extends Equatable {
  final String name;
  final String language;
  final String condition;
  final bool foil;
  final double marketPrice;

  const MagicCard({
    required this.name,
    this.language = 'Português',
    this.condition = 'NM',
    this.foil = false,
    this.marketPrice = 0,
  });

  double suggestedPrice(double discountPercent) =>
      marketPrice * (1 - discountPercent / 100);

  @override
  List<Object?> get props => [name, language, condition, foil, marketPrice];
}
