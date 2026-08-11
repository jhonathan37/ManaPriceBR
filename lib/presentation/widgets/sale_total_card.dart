import 'package:flutter/material.dart';

class SaleTotalCard extends StatelessWidget {
  const SaleTotalCard({
    super.key,
    required this.itemCount,
    required this.referenceTotal,
    required this.finalTotal,
  });

  final int itemCount;
  final double referenceTotal;
  final double finalTotal;

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final discount = referenceTotal - finalTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$itemCount carta${itemCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Referência: ${_money(referenceTotal)}'),
            Text('Desconto: ${_money(discount)}'),
            const Divider(),
            Text(
              'Total da venda: ${_money(finalTotal)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
