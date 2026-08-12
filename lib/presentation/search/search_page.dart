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
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              labelText: 'Nome da carta',
              hintText: 'Ex.: The One Ring',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
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
            'O ManaPrice busca a carta pelo nome, mostra a imagem e usa o menor preço real retornado pela LigaMagic. Depois você aplica o desconto e copia a mensagem para enviar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
