import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      discountPercent: _discount,
      setCode: widget.filters['setCode'] as String?,
      setName: widget.filters['setName'] as String?,
      collectorNumber: widget.filters['collectorNumber'] as String?,
      language: widget.filters['language'] as String? ?? 'Português',
      condition: widget.filters['condition'] as String? ?? 'NM',
      foil: widget.filters['foil'] as bool? ?? false,
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

  Future<void> _copyMessage() async {
    final item = _item;
    if (item == null || !item.priceAvailable) return;

    final message = '${item.cardName}\n'
        'Menor preço encontrado: ${_money(item.referencePrice)}\n'
        'Desconto: ${_discount.toStringAsFixed(0)}%\n'
        'Valor final: ${_money(item.finalValue)}';

    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem copiada. Agora é só enviar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.filters['name'] as String? ?? 'Carta';
    final setName = widget.filters['setName'] as String?;
    final condition = widget.filters['condition'] as String? ?? 'NM';
    final foil = widget.filters['foil'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Cotação da carta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Carta não encontrada: $name',
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
                            if (_item!.imageUrl != null && _item!.imageUrl!.isNotEmpty) ...[
                              Center(
                                child: Image.network(
                                  _item!.imageUrl!,
                                  height: 280,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              _item!.cardName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${setName ?? 'Qualquer edição'} • $condition • ${foil ? 'Foil' : 'Não foil'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            if (_item!.priceAvailable) ...[
                              const Text('Menor preço real encontrado na LigaMagic'),
                              Text(
                                _money(_item!.referencePrice),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                              const Text('Valor final para enviar'),
                              Text(
                                _money(_item!.finalValue),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Text(
                                'Não foi possível obter o preço da LigaMagic agora.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'A carta foi localizada, mas o app não inventa um valor quando a fonte real não responde.',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_item!.priceAvailable) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _copyMessage,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar mensagem para enviar'),
                      ),
                    ],
                  ],
                ),
    );
  }
}
