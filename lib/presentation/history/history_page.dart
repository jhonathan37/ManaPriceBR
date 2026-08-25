import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/quote_history_store.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([QuoteHistoryStore.history(), QuoteHistoryStore.favorites()]);
    if (!mounted) return;
    setState(() {
      _history = values[0];
      _favorites = values[1];
      _loading = false;
    });
  }

  String _subtitle(Map<String, dynamic> item) {
    final edition = (item['setName'] as String?)?.trim();
    final condition = item['condition'] as String? ?? 'NM';
    final foil = item['foil'] == true ? 'Foil' : 'Não foil';
    return '${edition == null || edition.isEmpty ? 'Edição não informada' : edition} • $condition • $foil';
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await QuoteHistoryStore.toggleFavorite(item);
    await _load();
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    await QuoteHistoryStore.removeHistory(item);
    await _load();
  }

  Widget _list(List<Map<String, dynamic>> items, {required bool favorites}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(favorites ? Icons.star_outline_rounded : Icons.history_rounded, size: 52),
            const SizedBox(height: 12),
            Text(favorites ? 'Nenhuma carta favorita ainda.' : 'Seu histórico vai aparecer aqui.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(favorites ? 'Favorite as cartas que você consulta mais.' : 'Faça uma cotação e volte quando quiser sem preencher tudo novamente.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
    }
    final favoriteIds = _favorites.map(QuoteHistoryStore.idOf).toSet();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String? ?? 'Carta';
        final fav = favoriteIds.contains(QuoteHistoryStore.idOf(item));
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/result', extra: item),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.style_rounded)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(_subtitle(item), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
                IconButton(tooltip: fav ? 'Remover dos favoritos' : 'Favoritar', onPressed: () => _toggle(item), icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded)),
                if (!favorites) PopupMenuButton<String>(onSelected: (v) { if (v == 'remove') _remove(item); }, itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remover do histórico'))]),
              ]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suas cartas'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Histórico', icon: Icon(Icons.history_rounded)), Tab(text: 'Favoritos', icon: Icon(Icons.star_rounded))]),
        actions: [
          IconButton(tooltip: 'Atualizar', onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          IconButton(tooltip: 'Limpar histórico', onPressed: _history.isEmpty ? null : () async { await QuoteHistoryStore.clearHistory(); await _load(); }, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: TabBarView(controller: _tabs, children: [_list(_history, favorites: false), _list(_favorites, favorites: true)]),
    );
  }
}
