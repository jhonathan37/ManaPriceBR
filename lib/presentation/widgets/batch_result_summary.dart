import 'package:flutter/material.dart';

import '../../domain/entities/batch_lookup_result.dart';

class BatchResultSummary extends StatelessWidget {
  const BatchResultSummary({super.key, required this.result});

  final BatchLookupResult result;

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
            Text('Resultado do lote', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Total processado: ${result.total}'),
            Text('Encontradas: ${result.successful}'),
            Text('Com erro: ${result.failedNames.length}'),
            Text('Referência: ${_money(result.referenceTotal)}'),
            const Divider(),
            Text(
              'Total da venda: ${_money(result.finalTotal)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (result.failedNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Não encontradas:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.failedNames.map((name) => Text('• $name')),
            ],
          ],
        ),
      ),
    );
  }
}
