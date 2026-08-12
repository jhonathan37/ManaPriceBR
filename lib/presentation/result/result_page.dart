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

    final item = await _provider.find(
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
          priceAvailable: item.priceAvailable,
          sourceName: item.sourceName,
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
                        Text(
                          'Carta não encontrada: $name. Confira a grafia ou tente fotografar novamente.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!_item!.priceAvailable)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Carta encontrada no catálogo. O preço brasileiro está temporariamente indisponível porque a fonte de preço não respondeu.',
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
                            if (_item!.sourceName != null) ...[
                              const SizedBox(height: 6),
                              Text('Fonte: ${_item!.sourceName}'),
                            ],
                            const Divider(height: 32),
                            if (_item!.priceAvailable) ...[
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
                            ] else ...[
                              Text(
                                'Preço BR indisponível no momento',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text('O app não inventa nem converte um preço estrangeiro para parecer preço da LigaMagic.'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_item!.priceAvailable) ...[
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
                  ],
                ),
    );
  }
}
