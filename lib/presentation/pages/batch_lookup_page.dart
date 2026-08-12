import 'package:flutter/material.dart';

import '../../domain/entities/batch_card_request.dart';
import '../../domain/entities/batch_lookup_result.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/services/batch_lookup_service.dart';
import '../widgets/batch_input.dart';
import '../widgets/batch_result_summary.dart';
import '../widgets/batch_progress_card.dart';

class BatchLookupPage extends StatefulWidget {
  const BatchLookupPage({super.key, required this.findCard});

  final Future<SaleItem?> Function(String cardName) findCard;

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
          ],
        ],
      ),
    );
  }
}
