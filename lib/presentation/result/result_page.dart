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
      imageUrl: widget.filters['imageUrl'] as String?,
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
          editionCode: item.editionCode,
          averagePrice: item.averagePrice,
          maximumPrice: item.maximumPrice,
          priceVerified: item.priceVerified,
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
    final setCode = widget.filters['setCode'] as String?;
    final collectorNumber = widget.filters['collectorNumber'] as String?;
    final language = widget.filters['language'] as String? ?? 'Português';
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
                            if (_item!.imageUrl != null &&
                                _item!.imageUrl!.trim().isNotEmpty) ...[
                              Center(
                                child: _CardImage(url: _item!.imageUrl!),
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
                              const SizedBox(height: 18),
                              Text('Desconto: ${_discount.toStringAsFixed(0)}%'),
                              Slider(
                                value: _discount,
                                min: 0,
                                max: 50,
                                divisions: 50,
                                label: '${_discount.toStringAsFixed(0)}%',
                                onChanged: _setDiscount,
                              ),
                              Text(
                                'Valor final: ${_money(_item!.finalValue)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _copyMessage,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar mensagem'),
                              ),
                            ] else ...[
                              const Text(
                                'Preço não confirmado na LigaMagic para esses filtros.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              title: const Text('Detalhes técnicos'),
                              subtitle: Text(
                                _item!.priceVerified
                                    ? 'Preço confirmado pela LigaMagic'
                                    : 'Preço sem confirmação final',
                              ),
                              children: [
                                _TechnicalRow(
                                  label: 'Fonte',
                                  value: _item!.sourceName ?? 'LigaMagic',
                                ),
                                _TechnicalRow(
                                  label: 'Nome pesquisado',
                                  value: name,
                                ),
                                _TechnicalRow(
                                  label: 'Nome canônico',
                                  value: _item!.cardName,
                                ),
                                _TechnicalRow(
                                  label: 'Idioma',
                                  value: language,
                                ),
                                _TechnicalRow(
                                  label: 'Edição solicitada',
                                  value: [
                                    if (setCode != null && setCode.isNotEmpty) setCode,
                                    if (setName != null && setName.isNotEmpty) setName,
                                  ].join(' • ').isEmpty
                                      ? 'Qualquer edição'
                                      : [
                                          if (setCode != null && setCode.isNotEmpty) setCode,
                                          if (setName != null && setName.isNotEmpty) setName,
                                        ].join(' • '),
                                ),
                                _TechnicalRow(
                                  label: 'Edição usada no preço',
                                  value: _item!.editionCode ?? 'Não identificada',
                                ),
                                _TechnicalRow(
                                  label: 'Collector',
                                  value: collectorNumber ?? 'Não filtrado',
                                ),
                                _TechnicalRow(
                                  label: 'Condição',
                                  value: condition,
                                ),
                                _TechnicalRow(
                                  label: 'Acabamento',
                                  value: foil ? 'Foil' : 'Não foil',
                                ),
                                if (_item!.priceAvailable)
                                  _TechnicalRow(
                                    label: 'Preço mínimo',
                                    value: _money(_item!.referencePrice),
                                  ),
                                if (_item!.averagePrice != null)
                                  _TechnicalRow(
                                    label: 'Preço médio',
                                    value: _money(_item!.averagePrice!),
                                  ),
                                if (_item!.maximumPrice != null)
                                  _TechnicalRow(
                                    label: 'Preço máximo',
                                    value: _money(_item!.maximumPrice!),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TechnicalRow extends StatelessWidget {
  const _TechnicalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CardImage extends StatefulWidget {
  const _CardImage({required this.url});

  final String url;

  @override
  State<_CardImage> createState() => _CardImageState();
}

class _CardImageState extends State<_CardImage> {
  late String _currentUrl;
  bool _retried = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url.trim();
  }

  @override
  void didUpdateWidget(covariant _CardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _currentUrl = widget.url.trim();
      _retried = false;
      _failed = false;
    }
  }

  String? _fallbackUrl(String url) {
    if (url.contains('/normal/')) {
      return url.replaceFirst('/normal/', '/small/');
    }
    if (url.contains('normal=')) {
      return url.replaceFirst('normal=', 'small=');
    }
    return null;
  }

  void _handleError() {
    final fallback = _fallbackUrl(_currentUrl);
    if (!_retried && fallback != null && fallback != _currentUrl) {
      setState(() {
        _retried = true;
        _currentUrl = fallback;
      });
      return;
    }
    setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: 48),
              SizedBox(height: 8),
              Text('Imagem indisponível para esta impressão.'),
            ],
          ),
        ),
      );
    }

    return Image.network(
      _currentUrl,
      key: ValueKey(_currentUrl),
      height: 280,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleError();
        });
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
