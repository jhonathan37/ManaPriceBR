import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/scryfall_catalog_client.dart';
import '../../domain/entities/card_printing.dart';

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
  List<CardPrinting> _printings = const [];
  CardPrinting? _selectedPrinting;
  String? _resolvedImageUrl;
  bool _loadingSuggestions = false;
  bool _loadingPrintings = false;
  bool _foil = false;
  String _condition = 'NM';

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
    setState(() {
      _selectedPrinting = null;
      _printings = const [];
      _resolvedImageUrl = null;
    });

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

  Future<void> _loadPrintings(String name) async {
    setState(() {
      _loadingPrintings = true;
      _selectedPrinting = null;
      _printings = const [];
      _resolvedImageUrl = null;
    });
    try {
      final resolved = await _catalog.find(name);
      final items = await _catalog.printings(resolved?.name ?? name);
      if (!mounted || _controller.text.trim() != name) return;
      setState(() {
        _printings = items;
        _resolvedImageUrl = resolved?.imageUrl ??
            (items.isNotEmpty ? items.first.imageUrl : null);
        _loadingPrintings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrintings = false);
    }
  }

  void _selectSuggestion(String name) {
    _controller.text = name;
    _controller.selection = TextSelection.collapsed(offset: name.length);
    setState(() => _suggestions = const []);
    _loadPrintings(name);
  }

  Future<void> _ensurePrintings() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _printings.isNotEmpty || _loadingPrintings) return;
    await _loadPrintings(name);
  }

  Future<void> _search() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome da carta.')),
      );
      return;
    }

    await _ensurePrintings();
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _suggestions = const []);
    final printing = _selectedPrinting;
    context.push('/result', extra: {
      'name': name,
      'setCode': printing?.setCode,
      'setName': printing?.setName,
      'collectorNumber': printing?.collectorNumber,
      'imageUrl': printing?.imageUrl ?? _resolvedImageUrl,
      'condition': _condition,
      'foil': _foil,
      'language': 'Português',
    });
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
              hintText: 'Português ou inglês, ex.: Testemunha Eterna',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _suggestions = const [];
                          _printings = const [];
                          _selectedPrinting = null;
                          _resolvedImageUrl = null;
                        });
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
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Mais filtros'),
            subtitle: Text(
              '${_selectedPrinting?.setName ?? 'Qualquer edição'} • $_condition • ${_foil ? 'Foil' : 'Não foil'}',
            ),
            onExpansionChanged: (expanded) {
              if (expanded) _ensurePrintings();
            },
            children: [
              if (_loadingPrintings)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                )
              else if (_printings.isNotEmpty)
                DropdownButtonFormField<CardPrinting?>(
                  initialValue: _selectedPrinting,
                  decoration: const InputDecoration(labelText: 'Edição'),
                  items: [
                    const DropdownMenuItem<CardPrinting?>(
                      value: null,
                      child: Text('Qualquer edição'),
                    ),
                    ..._printings.map(
                      (p) => DropdownMenuItem<CardPrinting?>(
                        value: p,
                        child: Text(p.label, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedPrinting = value),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(labelText: 'Condição'),
                items: const ['NM', 'SP', 'MP', 'HP', 'DMG']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _condition = value);
                },
              ),
              SwitchListTile(
                title: const Text('Foil'),
                value: _foil,
                onChanged: (value) => setState(() => _foil = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.price_check),
            label: const Text('Buscar preço na LigaMagic'),
          ),
        ],
      ),
    );
  }
}
