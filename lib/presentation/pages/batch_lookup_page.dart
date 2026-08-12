import 'package:flutter/material.dart';

import '../../domain/entities/batch_card_request.dart';
import '../../domain/entities/batch_lookup_result.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/services/batch_lookup_service.dart';
import '../widgets/batch_input.dart';
import '../widgets/batch_result_summary.dart';

class BatchLookupPage extends StatefulWidget {
  const BatchLookupPage({
    super.key,
    required this.findCard,
    required this.onAddToSale,
  });

  final Future<SaleItem?> Function(String cardName) findCard;
  final ValueChanged<List<SaleItem>> onAddToSale;

  @override
  State<BatchLookupPage> createState() => _BatchLookupPageState();
}

class _BatchLookupPageState extends State<BatchLookupPage> {
  final _controller = TextEditingController();
  final _service = const BatchLookupService();
  BatchLookupResult? _result;
  int _completed = 0;
  int _total = 0;
  bool _loading = false;
  bool _addedToSale = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final request = BatchCardRequest(
      cardNames: _controller.text.split(RegExp(r'[\r\n]+')),
      language: 'Português',
      condition: 'NM',
      foil: false,
    );

    if (request.normalizedNames.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
      _completed = 0;
      _total = request.normalizedNames.length;
      _addedToSale = false;
    });

    final result = await _service.lookup(
      request,
      findCard: widget.findCard,
      onProgress: (completed, total) {
        if (!mounted) return;
        setState(() {
          _completed = completed;
          _total = total;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _addResultToSale() {
    final result = _result;
    if (result == null || result.items.isEmpty || _addedToSale) return;
    widget.onAddToSale(List.unmodifiable(result.items));
    setState(() => _addedToSale = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.items.length} carta(s) adicionada(s) à venda.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? null : (_completed / _total).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta em lote')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BatchInput(controller: _controller, onRun: _loading ? () {} : _run),
          if (_loading && progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('Processando $_completed/$_total'),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            BatchResultSummary(result: _result!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _result!.items.isEmpty || _addedToSale ? null : _addResultToSale,
              icon: Icon(_addedToSale ? Icons.check : Icons.add_shopping_cart),
              label: Text(_addedToSale ? 'ADICIONADO À VENDA' : 'ADICIONAR ENCONTRADAS À VENDA'),
            ),
          ],
        ],
      ),
    );
  }
}
