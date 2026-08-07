import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> filters;

  const ResultPage({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    final name = filters['name'] as String? ?? 'Carta';
    final language = filters['language'] as String? ?? 'Português';
    final condition = filters['condition'] as String? ?? 'NM';
    final foil = filters['foil'] as bool? ?? false;

    // Valor demonstrativo da primeira versão. A fonte real de preços será
    // ligada posteriormente através do PriceProvider.
    const marketPrice = 100.0;
    const discount = 15.0;
    final suggested = marketPrice * (1 - discount / 100);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('$language • $condition${foil ? ' • Foil' : ''}'),
                  const Divider(height: 32),
                  const Text('Preço encontrado'),
                  Text('R\$ ${marketPrice.toStringAsFixed(2).replaceAll('.', ',')}', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  const Text('Desconto aplicado'),
                  Text('${discount.toStringAsFixed(0)}%'),
                  const SizedBox(height: 20),
                  const Text('Preço sugerido'),
                  Text('R\$ ${suggested.toStringAsFixed(2).replaceAll('.', ',')}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final text = '$name | $condition | R\$ ${suggested.toStringAsFixed(2).replaceAll('.', ',')}';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anúncio pronto: $text')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar anúncio'),
          ),
        ],
      ),
    );
  }
}
