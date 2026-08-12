import 'package:flutter/material.dart';

import '../../domain/entities/sale_item.dart';

class SaleTotals extends StatelessWidget {
  const SaleTotals({super.key, required this.items});

  final List<SaleItem> items;

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final reference = items.fold<double>(0, (sum, item) => sum + item.referencePrice);
    final total = items.fold<double>(0, (sum, item) => sum + item.finalValue);
    final discount = reference - total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo da venda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text('Cartas: ${items.length}'),
            Text('Preço de referência: ${_money(reference)}'),
            Text('Desconto total: ${_money(discount)}'),
            const Divider(),
            Text(
              'Você recebe: ${_money(total)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
