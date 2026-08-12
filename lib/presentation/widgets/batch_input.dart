import 'package:flutter/material.dart';

class BatchInput extends StatelessWidget {
  const BatchInput({super.key, required this.controller, required this.onRun});

  final TextEditingController controller;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Cartas para consultar',
            hintText: 'Uma carta por linha',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRun,
          icon: const Icon(Icons.play_arrow),
          label: const Text('PROCESSAR CARTAS'),
        ),
      ],
    );
  }
}
