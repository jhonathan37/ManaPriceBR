import 'package:flutter/material.dart';

import 'card_scanner_page.dart';
import '../widgets/card_search_form.dart';
import '../widgets/card_price_result.dart';

class CardSearchPage extends StatefulWidget {
  const CardSearchPage({super.key});

  @override
  State<CardSearchPage> createState() => _CardSearchPageState();
}

class _CardSearchPageState extends State<CardSearchPage> {
  final _nameController = TextEditingController();
  String _language = 'Português';
  String _condition = 'NM';
  bool _foil = false;
  bool _loading = false;
  String? _error;
  String? _searchedName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardScannerPage(
          onCardDetected: (detected) {
            final name = detected['name']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              _nameController.text = name;
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (!mounted) return;
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _error = null;
        _searchedName = null;
      });
    }
  }

  Future<void> _search() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Digite o nome da carta.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _searchedName = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _searchedName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ManaPriceBR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Consultar carta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _openScanner,
              icon: const Icon(Icons.document_scanner),
              label: const Text('ESCANEAR CARTA'),
            ),
            const SizedBox(height: 16),
            CardSearchForm(
              nameController: _nameController,
              language: _language,
              condition: _condition,
              foil: _foil,
              loading: _loading,
              onLanguageChanged: (value) => setState(() => _language = value ?? _language),
              onConditionChanged: (value) => setState(() => _condition = value ?? _condition),
              onFoilChanged: (value) => setState(() => _foil = value),
              onSearch: _search,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_searchedName != null) ...[
              const SizedBox(height: 24),
              CardPriceResult(
                cardName: _searchedName!,
                referencePrice: 0,
                discountPercent: 0,
                finalValue: 0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
