import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/card_effect_search.dart';

class EffectSearchPage extends StatefulWidget {
  const EffectSearchPage({super.key});

  @override
  State<EffectSearchPage> createState() => _EffectSearchPageState();
}

class _EffectSearchPageState extends State<EffectSearchPage> {
  final _controller = TextEditingController();
  final _search = CardEffectSearch();
  List<CardEffectSearchResult> _results = const [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text.trim();
    if (text.length < 3) {
      setState(() => _message = 'Descreva pelo menos um efeito da carta.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
      _results = const [];
    });
    final results = await _search.search(text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = results;
      _message = results.isEmpty
          ? 'Não encontrei cartas com esses efeitos. Tente usar palavras mais específicas.'
          : null;
    });
  }

  void _choose(CardEffectSearchResult card) {
    context.push('/search', extra: {'name': card.name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar por efeito/texto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Não sabe o nome da carta?',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Descreva o que você lembra. Ex.: “sacrifica criatura compra carta” ou “destrói artefato encantamento”.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            decoration: const InputDecoration(
              labelText: 'Efeito ou trecho que você lembra',
              hintText: 'Ex.: sacrifica uma criatura e compra uma carta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.auto_awesome),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.manage_search),
            label: Text(_loading ? 'Procurando cartas...' : 'Buscar cartas'),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Possíveis cartas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._results.map(
              (card) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  isThreeLine: true,
                  leading: card.imageUrl == null
                      ? const Icon(Icons.style_outlined, size: 40)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            card.imageUrl!,
                            width: 42,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.style_outlined, size: 40),
                          ),
                        ),
                  title: Text(
                    card.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if ((card.typeLine ?? '').isNotEmpty) card.typeLine!,
                      _short(card.oracleText),
                    ].join('\n'),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _choose(card),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _short(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 150) return clean;
    return '${clean.substring(0, 150).trim()}…';
  }
}
