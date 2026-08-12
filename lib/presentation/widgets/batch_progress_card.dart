import 'package:flutter/material.dart';

import '../../domain/entities/batch_lookup_progress.dart';

class BatchProgressCard extends StatelessWidget {
  const BatchProgressCard({super.key, required this.progress});

  final BatchLookupProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.percentage * 100).clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Processando cartas', style: Theme.of(context).textTheme.titleMedium),
                Text('${percent.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress.percentage),
            const SizedBox(height: 10),
            Text('Concluídas: ${progress.completed}/${progress.total}'),
            Text('Encontradas: ${progress.successful}'),
            Text('Com erro: ${progress.failed}'),
          ],
        ),
      ),
    );
  }
}
