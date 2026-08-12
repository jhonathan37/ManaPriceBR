import 'package:flutter/material.dart';

import '../../domain/entities/sale_item.dart';
import '../widgets/sale_list.dart';
import '../widgets/sale_totals.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final List<SaleItem> _items = [];

  void _remove(int index) => setState(() => _items.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha venda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SaleList(items: _items, onRemove: _remove),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 16),
            SaleTotals(items: _items),
          ],
        ],
      ),
    );
  }
}
