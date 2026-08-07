import 'package:flutter/material.dart';

class BatchPage extends StatefulWidget {
  const BatchPage({super.key});

  @override
  State<BatchPage> createState() => _BatchPageState();
}

class _BatchPageState extends State<BatchPage> {
  final controller = TextEditingController();
  List<String> cards = [];

  void parseCards() {
    final lines = controller.text
        .split(RegExp(r'[\n,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() => cards = lines);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta em lote')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Cole uma carta por linha ou separe por vírgulas.'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Lightning Bolt\nCounterspell\nMana Crypt',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: parseCards,
            icon: const Icon(Icons.search),
            label: const Text('Preparar consulta'),
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('${cards.length} cartas preparadas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...cards.asMap().entries.map(
              (entry) => ListTile(
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(entry.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
