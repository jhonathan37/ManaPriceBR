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
    final item = await _provider.find(
      widget.filters['name'] as String? ?? '',
      setCode: widget.filters['setCode'] as String?,
      setName: widget.filters['setName'] as String?,
      collectorNumber: widget.filters['collectorNumber'] as String?,
      language: widget.filters['language'] as String? ?? 'Português',
      condition: widget.filters['condition'] as String? ?? 'NM',
      foil: widget.filters['foil'] as bool? ?? false,
      discountPercent: _discount,
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
    final setName = widget.filters['setName'] as String? ?? 'Edição não informada';
    final setCode = widget.filters['setCode'] as String? ?? '';
    final collector = widget.filters['collectorNumber'] as String? ?? '';
    final selectedImage = widget.filters['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Menor preço real')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'A impressão exata não foi informada. Volte e selecione a edição da carta.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((_item!.imageUrl ?? selectedImage) != null) ...[
                              Center(
                                child: Image.network(
                                  _item!.imageUrl ?? selectedImage!,
                                  height: 280,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('$setName${setCode.isEmpty ? '' : ' ($setCode)'}${collector.isEmpty ? '' : ' • #$collector'}'),
                            Text('$language • $condition • ${foil ? 'Foil' : 'Não Foil'}'),
                            const Divider(height: 32),
                            if (_item!.priceAvailable) ...[
                              const Text('Menor preço real encontrado na LigaMagic'),
                              Text(
                                _money(_item!.referencePrice),
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Esse valor corresponde à combinação selecionada de edição, idioma, condição e acabamento.',
                              ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Text(
                                'Nenhuma oferta compatível foi retornada pela LigaMagic.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'O ManaPriceBR não substitui esse valor por estimativa, conversão ou preço de outra edição.',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
