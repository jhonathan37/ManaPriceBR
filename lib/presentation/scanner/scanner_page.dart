import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool processing = false;

  Future<void> simulateRecognition() async {
    setState(() => processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => processing = false);
    context.push('/search');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear carta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 64),
                      SizedBox(height: 16),
                      Text('Aponte a câmera para a carta'),
                      SizedBox(height: 6),
                      Text('O nome será reconhecido automaticamente.'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: processing ? null : simulateRecognition,
                icon: processing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt),
                label: Text(processing ? 'Reconhecendo...' : 'Tirar foto'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.edit),
              label: const Text('Digitar o nome manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}
