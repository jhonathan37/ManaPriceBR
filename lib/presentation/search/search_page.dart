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
  final _catalog = ScryfallCatalogClient();

  String language = 'Português';
  String condition = 'NM';
  bool foil = false;
  bool _loadingEditions = false;
  String? _catalogError;
  List<CardPrinting> _printings = const [];
  CardPrinting? _selectedPrinting;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEditions() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome exato da carta.')),
      );
      return;
    }

    setState(() {
      _loadingEditions = true;
      _catalogError = null;
      _printings = const [];
      _selectedPrinting = null;
    });

    try {
      final exact = await _catalog.find(name);
      if (exact == null) {
        if (!mounted) return;
        setState(() {
          _catalogError = 'Carta não encontrada com esse nome exato.';
          _loadingEditions = false;
        });
        return;
      }

      _controller.text = exact.name;
      final printings = await _catalog.printings(exact.name);
      if (!mounted) return;
      setState(() {
        _printings = printings;
        _selectedPrinting = printings.isEmpty ? null : printings.first;
        _loadingEditions = false;
        _catalogError = printings.isEmpty
            ? 'Nenhuma edição foi encontrada para essa carta.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'Não foi possível carregar as edições agora.';
        _loadingEditions = false;
      });
    }
  }

  void _search() {
    final name = _controller.text.trim();
    final printing = _selectedPrinting;
    if (name.isEmpty || printing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a carta e selecione a edição antes de consultar.'),
        ),
      );
      return;
    }

    if (foil && !printing.foilAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa impressão não possui versão Foil no catálogo.')),
      );
      return;
    }
    if (!foil && !printing.nonfoilAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa impressão não possui versão não-Foil no catálogo.')),
      );
      return;
    }

    context.push('/result', extra: {
      'name': name,
      'language': language,
      'condition': condition,
      'foil': foil,
      'setCode': printing.setCode,
      'setName': printing.setName,
      'collectorNumber': printing.collectorNumber,
      'imageUrl': printing.imageUrl,
    });
  }

  CardPrinting? _printingById(String? id) {
    if (id == null) return null;
    for (final printing in _printings) {
      if (printing.id == id) return printing;
    }
    return null;
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
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadEditions(),
            onChanged: (_) {
              if (_printings.isNotEmpty || _selectedPrinting != null) {
                setState(() {
                  _printings = const [];
                  _selectedPrinting = null;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Nome exato da carta',
              hintText: 'Ex.: The One Ring',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/scanner'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Ler nome pela câmera'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _loadingEditions ? null : _loadEditions,
            icon: _loadingEditions
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.style_outlined),
            label: Text(_loadingEditions ? 'Carregando edições...' : 'Carregar edições'),
          ),
          if (_catalogError != null) ...[
            const SizedBox(height: 12),
            Text(_catalogError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_printings.isNotEmpty) ...[
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedPrinting?.id),
              initialValue: _selectedPrinting?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Edição / impressão'),
              items: _printings
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
                  .toList(growable: false),
              onChanged: (id) => setState(() => _selectedPrinting = _printingById(id)),
            ),
            if (_selectedPrinting?.imageUrl != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Image.network(
                  _selectedPrinting!.imageUrl!,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: const InputDecoration(labelText: 'Idioma'),
            items: const [
              DropdownMenuItem(value: 'Português', child: Text('Português')),
              DropdownMenuItem(value: 'Inglês', child: Text('Inglês')),
              DropdownMenuItem(value: 'Espanhol', child: Text('Espanhol')),
            ],
            onChanged: (value) => setState(() => language = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: condition,
            decoration: const InputDecoration(labelText: 'Condição'),
            items: const [
              DropdownMenuItem(value: 'NM', child: Text('NM - Near Mint')),
              DropdownMenuItem(value: 'SP', child: Text('SP - Slightly Played')),
              DropdownMenuItem(value: 'MP', child: Text('MP - Moderately Played')),
              DropdownMenuItem(value: 'HP', child: Text('HP - Heavily Played')),
            ],
            onChanged: (value) => setState(() => condition = value!),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foil'),
            value: foil,
            onChanged: (value) => setState(() => foil = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedPrinting == null ? null : _search,
            icon: const Icon(Icons.currency_exchange),
            label: const Text('Buscar menor preço real'),
          ),
        ],
      ),
    );
  }
}
