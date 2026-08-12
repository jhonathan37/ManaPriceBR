import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/card_ocr_reader.dart';

class CardScannerPage extends StatefulWidget {
  const CardScannerPage({super.key, required this.onCardNameDetected});

  final ValueChanged<String> onCardNameDetected;

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage> {
  final _picker = ImagePicker();
  final _ocr = CardOcrReader();
  bool _loading = false;
  String? _detectedName;
  String? _error;

  Future<void> _capture() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (image == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _detectedName = null;
    });

    try {
      final name = await _ocr.readCardName(image.path);
      if (!mounted) return;
      if (name == null) {
        setState(() => _error = 'Não consegui identificar o nome da carta.');
        return;
      }
      setState(() => _detectedName = name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Falha ao processar a imagem.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de carta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _capture,
              icon: const Icon(Icons.photo_camera),
              label: Text(_loading ? 'Lendo carta...' : 'TIRAR FOTO'),
            ),
            const SizedBox(height: 20),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_detectedName != null) ...[
              Text('Carta identificada', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_detectedName!, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => widget.onCardNameDetected(_detectedName!),
                child: const Text('USAR ESTE NOME'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
