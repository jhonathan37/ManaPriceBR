import 'package:flutter/material.dart';

class CardPriceResult extends StatelessWidget {
  const CardPriceResult({
    super.key,
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    required this.finalValue,
    this.imageUrl,
  });

  final String cardName;
  final double referencePrice;
  final double discountPercent;
  final double finalValue;
  final String? imageUrl;

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 72),
                ),
              ),
            Text(cardName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Preço de referência: ${_money(referencePrice)}'),
            Text('Desconto: ${discountPercent.toStringAsFixed(0)}%'),
            const Divider(),
            Text(
              'Você recebe: ${_money(finalValue)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
