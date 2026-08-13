import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/scryfall_catalog_client.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialName});

  final String? initialName;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  final ScryfallCatalogClient _catalog = ScryfallCatalogClient();
  Timer? _debounce;
  List<String> _suggestions = const [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loadingSuggestions = true);

      try {
        final items = await _catalog.autocomplete(query);
        if (!mounted || _controller.text.trim() != query) return;
        setState(() {
          _suggestions = items;
          _loadingSuggestions = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
        });
      }
    });
  }

  void _selectSuggestion(String name) {
    _controller.text = name;
    _controller.selection = TextSelection.collapsed(offset: name.length);
    setState(() => _suggestions = const []);
    _search();
  }

  void _search() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome da carta.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _suggestions = const []);
    context.push('/result', extra: {'name': name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisar carta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            autofocus: widget.initialName?.isEmpty ?? true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Nome da carta',
              hintText: 'Comece a digitar, ex.: Sol Ri...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _suggestions = const []);
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_loadingSuggestions) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _suggestions
                    .map(
                      (name) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.auto_awesome),
                        title: Text(name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectSuggestion(name),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/scanner'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Ler nome pela câmera'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.currency_exchange),
            label: const Text('Buscar menor preço real'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Digite só algumas letras e toque na carta certa. Depois o ManaPrice mostra a imagem, busca o menor preço retornado pela LigaMagic e permite aplicar o desconto.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
