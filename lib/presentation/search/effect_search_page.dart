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
      setState(() => _message = 'Me conte um pouco do que você lembra da carta.');
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
          ? 'Não achei uma boa combinação ainda. Tente lembrar outro detalhe: cor, tipo, o que acontece quando entra, morre ou ataca.'
          : null;
    });
  }

  void _choose(CardEffectSearchResult card) {
    context.push('/search', extra: {'name': card.name});
  }

  void _useExample(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Encontrar pela descrição')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.psychology_alt_rounded, color: colors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Não lembra o nome? Tudo bem.',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Escreva do jeito que você falaria com outro jogador. Eu procuro as cartas mais parecidas.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            decoration: const InputDecoration(
              labelText: 'O que você lembra da carta?',
              hintText: 'Ex.: criatura preta que quando morre compra uma carta',
              prefixIcon: Icon(Icons.auto_awesome_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Experimente uma ideia',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.water_drop_outlined, size: 18),
                label: const Text('quando morre compra carta'),
                onPressed: () => _useExample('criatura preta que quando morre compra uma carta'),
              ),
              ActionChip(
                avatar: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('destrói artefato'),
                onPressed: () => _useExample('destrói artefato ou encantamento'),
              ),
              ActionChip(
                avatar: const Icon(Icons.favorite_border_rounded, size: 18),
                label: const Text('cria ficha e ganha vida'),
                onPressed: () => _useExample('cria ficha e ganha vida'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.manage_search_rounded),
            label: Text(_loading ? 'Procurando combinações...' : 'Encontrar cartas'),
          ),
          if (_loading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(minHeight: 5),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparando o que você descreveu com o texto das cartas…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.secondaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: colors.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_message!)),
                ],
              ),
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Essas parecem combinar',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${_results.length} opções',
                  style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Toque na carta que você reconhece para escolher a edição e consultar o preço.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ..._results.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _choose(card),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: card.imageUrl == null
                                ? Container(
                                    width: 58,
                                    height: 82,
                                    color: colors.surfaceContainerHighest,
                                    child: const Icon(Icons.style_outlined),
                                  )
                                : Image.network(
                                    card.imageUrl!,
                                    width: 58,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 58,
                                      height: 82,
                                      color: colors.surfaceContainerHighest,
                                      child: const Icon(Icons.style_outlined),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                if ((card.typeLine ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    card.typeLine!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    _scoreLabel(card.score),
                                    style: TextStyle(
                                      color: colors.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _short(card.oracleText),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _scoreLabel(int score) {
    if (score >= 6) return 'Combinação muito forte';
    if (score >= 4) return 'Combinação forte';
    if (score >= 2) return 'Boa possibilidade';
    return 'Possível combinação';
  }

  static String _short(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 165 ? clean : '${clean.substring(0, 165).trim()}…';
  }
}
