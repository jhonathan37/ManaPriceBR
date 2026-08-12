import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialName});

  final String? initialName;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  String language = 'Português';
  String condition = 'NM';
  bool foil = false;

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

  void _search() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome da carta.')),
      );
      return;
    }
    context.push('/result', extra: {
      'name': name,
      'language': language,
      'condition': condition,
      'foil': foil,
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
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              labelText: 'Nome da carta',
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
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text('Pesquisar'),
          ),
        ],
      ),
    );
  }
}
