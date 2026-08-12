import 'package:flutter/material.dart';

import '../../data/providers/card_price_provider.dart';
import '../../domain/entities/sale_item.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.filters});

  final Map<String, dynamic> filters;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final _provider = CardPriceProvider();
  SaleItem? _item;
  bool _loading = true;
  bool _usedFallback = false;
  double _discount = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = widget.filters['name'] as String? ?? '';
    final language = widget.filters['language'] as String? ?? 'Português';
    final condition = widget.filters['condition'] as String? ?? 'NM';
    final foil = widget.filters['foil'] as bool? ?? false;

    final real = await _provider.find(
      name,
      language: language,
      condition: condition,
      foil: foil,
      discountPercent: _discount,
      allowDemoFallback: false,
    );

    final item = real ?? await _provider.find(
      name,
      language: language,
      condition: condition,
      foil: foil,
      discountPercent: _discount,
      allowDemoFallback: true,
    );

    if (!mounted) return;
    setState(() {
      _item = item;
      _usedFallback = real == null && item != null;
      _loading = false;
    });
  }

  void _setDiscount(double value) {
    final item = _item;
    setState(() {
      _discount = value;
      if (item != null) {
        _item = SaleItem(
          cardName: item.cardName,
          referencePrice: item.referencePrice,
          discountPercent: value,
          imageUrl: item.imageUrl,
        );
      }
    });
  }

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final name = widget.filters['name'] as String? ?? 'Carta';
    final language = widget.filters['language'] as String? ?? 'Português';
    final condition = widget.filters['condition'] as String? ?? 'NM';
    final foil = widget.filters['foil'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 64),
                        const SizedBox(height: 16),
                        Text('Não foi possível obter preço para $name.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_usedFallback)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'A LigaMagic não respondeu à consulta. Mostrando preço de demonstração quando disponível.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_item!.imageUrl != null && _item!.imageUrl!.isNotEmpty) ...[
                              Center(
                                child: Image.network(
                                  _item!.imageUrl!,
                                  height: 260,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              _item!.cardName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('$language • $condition${foil ? ' • Foil' : ''}'),
                            const Divider(height: 32),
                            const Text('Preço de referência'),
                            Text(_money(_item!.referencePrice), style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 24),
                            Text('Desconto: ${_discount.toStringAsFixed(0)}%'),
                            Slider(
                              value: _discount,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              label: '${_discount.toStringAsFixed(0)}%',
                              onChanged: _setDiscount,
                            ),
                            const SizedBox(height: 12),
                            const Text('Você recebe'),
                            Text(
                              _money(_item!.finalValue),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        final text = '${_item!.cardName} | $condition | ${_money(_item!.finalValue)}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Anúncio pronto: $text')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar anúncio'),
                    ),
                  ],
                ),
    );
  }
}
