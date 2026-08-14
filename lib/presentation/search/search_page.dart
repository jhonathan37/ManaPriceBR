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
    });
    try {
      final items = await _catalog.printings(name);
      if (!mounted || _controller.text.trim() != name) return;
      setState(() {
        _printings = items;
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
              hintText: 'Comece a digitar, ex.: Sol Ri...',
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
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Mais filtros'),
            subtitle: const Text('Edição, condição e acabamento'),
            children: [
              if (_loadingPrintings) const LinearProgressIndicator(),
              DropdownButtonFormField<String?>(
                initialValue: _selectedPrinting?.id,
                decoration: const InputDecoration(
                  labelText: 'Edição',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Qualquer edição'),
                  ),
                  ..._printings.map(
                    (printing) => DropdownMenuItem<String?>(
                      value: printing.id,
                      child: Text(
                        printing.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedPrinting = id == null
                        ? null
                        : _printings.firstWhere((p) => p.id == id);
                    if (_selectedPrinting != null &&
                        !_selectedPrinting!.foilAvailable) {
                      _foil = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condição',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'NM', child: Text('NM')),
                  DropdownMenuItem(value: 'SP', child: Text('SP')),
                  DropdownMenuItem(value: 'MP', child: Text('MP')),
                  DropdownMenuItem(value: 'HP', child: Text('HP')),
                  DropdownMenuItem(value: 'D', child: Text('Danificada')),
                ],
                onChanged: (value) => setState(() => _condition = value ?? 'NM'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Foil'),
                subtitle: Text(_foil ? 'Buscar versão foil' : 'Buscar versão não foil'),
                value: _foil,
                onChanged: _selectedPrinting != null &&
                        !_selectedPrinting!.foilAvailable
                    ? null
                    : (value) => setState(() => _foil = value),
              ),
            ],
          ),
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
            'Você pode buscar rápido só pelo nome ou abrir Mais filtros para escolher edição, condição e foil.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
