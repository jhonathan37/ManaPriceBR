import 'package:flutter/material.dart';

import '../../domain/entities/sale_item.dart';

class SaleList extends StatelessWidget {
  const SaleList({super.key, required this.items, required this.onRemove});

  final List<SaleItem> items;
  final ValueChanged<int> onRemove;

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Nenhuma carta adicionada à venda.')),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item.imageUrl == null
                ? const CircleAvatar(child: Icon(Icons.style))
                : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl!)),
            title: Text(item.cardName),
            subtitle: Text(
              '${_money(item.referencePrice)} • ${item.discountPercent.toStringAsFixed(0)}% desconto',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _money(item.finalValue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
