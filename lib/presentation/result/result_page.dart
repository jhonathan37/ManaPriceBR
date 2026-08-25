import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/app_settings_store.dart';
import '../../data/local/quote_history_store.dart';
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
  bool _favorite = false;
  String? _loadError;
  double _discount = 20;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = await AppSettingsStore.load();
    final favorite = await QuoteHistoryStore.isFavorite(widget.filters);
    if (!mounted) return;
    setState(() {
      _discount = settings.discount;
      _favorite = favorite;
    });
    await _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
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

      await QuoteHistoryStore.add(widget.filters);
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _item = null;
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  void _setDiscount(double value) {
    final item = _item;
    setState(() {
      _discount = value;
      if (item != null) {
        _item = SaleItem(
          cardName: item.cardName,
          displayName: item.displayName,
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

  Future<void> _toggleFavorite() async {
    final favorite = await QuoteHistoryStore.toggleFavorite(widget.filters);
    if (!mounted) return;
    setState(() => _favorite = favorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(favorite ? 'Carta adicionada aos favoritos.' : 'Carta removida dos favoritos.')),
    );
  }

  String _money(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _copyMessage() async {
    final item = _item;
    if (item == null || !item.priceAvailable) return;

    final message = '${item.visibleName}\n'
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotação da carta'),
        actions: [
          IconButton(
            tooltip: _favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            onPressed: _toggleFavorite,
            icon: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Consultando catálogo e LigaMagic…', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            )
          : _item == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError == null ? 'Carta não encontrada: $name' : 'Não foi possível concluir a consulta agora.', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_item!.imageUrl != null && _item!.imageUrl!.trim().isNotEmpty) ...[
                              Center(child: _CardImage(url: _item!.imageUrl!)),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_item!.visibleName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      if (_item!.visibleName != _item!.cardName) ...[
                                        const SizedBox(height: 4),
                                        Text(_item!.cardName, style: theme.textTheme.bodySmall),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_item!.priceVerified)
                                  Chip(
                                    avatar: Icon(Icons.verified_rounded, size: 18, color: colors.primary),
                                    label: const Text('Verificado'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(avatar: const Icon(Icons.layers_rounded, size: 17), label: Text(setName ?? setCode ?? 'Qualquer edição')),
                                Chip(label: Text(condition)),
                                Chip(label: Text(foil ? 'Foil' : 'Não foil')),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_item!.priceAvailable) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer.withValues(alpha: .55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Menor preço encontrado na LigaMagic', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text(_money(_item!.referencePrice), style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1)),
                                    if (_item!.averagePrice != null || _item!.maximumPrice != null) ...[
                                      const SizedBox(height: 8),
                                      Text([
                                        if (_item!.averagePrice != null) 'Média ${_money(_item!.averagePrice!)}',
                                        if (_item!.maximumPrice != null) 'Máx. ${_money(_item!.maximumPrice!)}',
                                      ].join(' • '), style: theme.textTheme.bodySmall),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text('Desconto: ${_discount.toStringAsFixed(0)}%'),
                              Slider(value: _discount, min: 0, max: 50, divisions: 50, label: '${_discount.toStringAsFixed(0)}%', onChanged: _setDiscount),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sell_rounded),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Valor final', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                                    Text(_money(_item!.finalValue), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: FilledButton.icon(onPressed: _copyMessage, icon: const Icon(Icons.copy), label: const Text('Copiar cotação'))),
                                  const SizedBox(width: 10),
                                  IconButton.filledTonal(
                                    tooltip: _favorite ? 'Remover favorito' : 'Favoritar',
                                    onPressed: _toggleFavorite,
                                    icon: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Text('Preço não confirmado na LigaMagic para esses filtros.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                            ],
                            const SizedBox(height: 12),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              title: const Text('Detalhes técnicos'),
                              subtitle: Text(_item!.priceVerified ? 'Preço confirmado pela LigaMagic' : 'Preço sem confirmação final'),
                              children: [
                                _TechnicalRow(label: 'Fonte', value: _item!.sourceName ?? 'LigaMagic'),
                                _TechnicalRow(label: 'Nome pesquisado', value: name),
                                _TechnicalRow(label: 'Nome exibido', value: _item!.visibleName),
                                _TechnicalRow(label: 'Nome canônico', value: _item!.cardName),
                                _TechnicalRow(label: 'Idioma', value: language),
                                _TechnicalRow(
                                  label: 'Edição solicitada',
                                  value: [if (setCode != null && setCode.isNotEmpty) setCode, if (setName != null && setName.isNotEmpty) setName].join(' • ').isEmpty
                                      ? 'Qualquer edição'
                                      : [if (setCode != null && setCode.isNotEmpty) setCode, if (setName != null && setName.isNotEmpty) setName].join(' • '),
                                ),
                                _TechnicalRow(label: 'Edição usada no preço', value: _item!.editionCode ?? 'Não identificada'),
                                _TechnicalRow(label: 'Collector', value: collectorNumber ?? 'Não filtrado'),
                                _TechnicalRow(label: 'Condição', value: condition),
                                _TechnicalRow(label: 'Acabamento', value: foil ? 'Foil' : 'Não foil'),
                                if (_item!.priceAvailable) _TechnicalRow(label: 'Preço mínimo', value: _money(_item!.referencePrice)),
                                if (_item!.averagePrice != null) _TechnicalRow(label: 'Preço médio', value: _money(_item!.averagePrice!)),
                                if (_item!.maximumPrice != null) _TechnicalRow(label: 'Preço máximo', value: _money(_item!.maximumPrice!)),
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
          SizedBox(width: 145, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
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
    if (url.contains('/normal/')) return url.replaceFirst('/normal/', '/small/');
    if (url.contains('normal=')) return url.replaceFirst('normal=', 'small=');
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
        return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleError();
        });
        return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
