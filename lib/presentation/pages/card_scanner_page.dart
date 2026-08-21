import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/services/card_ocr_reader.dart';
import '../../core/services/oracle_text_matcher.dart';
import '../../data/datasources/scryfall_catalog_client.dart';

class CardScannerPage extends StatefulWidget {
  const CardScannerPage({super.key, required this.onCardNameDetected});

  final ValueChanged<String> onCardNameDetected;

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage>
    with WidgetsBindingObserver {
  final _ocr = CardOcrReader();
  final _catalog = ScryfallCatalogClient();
  final _oracleMatcher = OracleTextMatcher();

  CameraController? _camera;
  Timer? _scanTimer;
  bool _initializing = true;
  bool _processing = false;
  bool _completed = false;
  String? _error;
  String? _lastCandidate;
  int _sameCandidateCount = 0;
  String _status = 'Inicializando câmera...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _scanTimer?.cancel();
    await _camera?.dispose();
    _camera = null;

    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
        _status = 'Inicializando câmera...';
      });
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Nenhuma câmera disponível.');
      }
      final rear = cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final selected = rear.isNotEmpty ? rear.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() {
        _initializing = false;
        _status = 'Aponte para a carta. Lendo automaticamente...';
      });
      _scanTimer = Timer.periodic(
        const Duration(milliseconds: 1300),
        (_) => _scanOnce(),
      );
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.code == 'CameraAccessDenied'
            ? 'Permita o acesso à câmera para usar o scanner.'
            : 'Não foi possível abrir a câmera.';
        _status = 'Scanner indisponível';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Não foi possível iniciar o scanner.';
        _status = 'Scanner indisponível';
      });
    }
  }

  Future<void> _scanOnce() async {
    final camera = _camera;
    if (_processing || _completed || camera == null || !camera.value.isInitialized) {
      return;
    }

    _processing = true;
    try {
      final image = await camera.takePicture();
      final ocrResult = await _ocr.read(image.path);
      if (!mounted || _completed) return;

      String? candidate;
      final rawName = ocrResult.cardName?.trim();
      if (rawName != null && rawName.length >= 3) {
        final resolved = await _catalog.find(rawName).timeout(
          const Duration(seconds: 4),
          onTimeout: () => null,
        );
        if (!mounted || _completed) return;
        candidate = resolved?.displayName?.trim().isNotEmpty == true
            ? resolved!.displayName!.trim()
            : resolved?.name.trim();
      }

      if (candidate == null || candidate.isEmpty) {
        setState(() => _status = 'Nome incerto. Tentando pelo texto da carta...');
        final textMatch = await _oracleMatcher
            .findFromOcrText(ocrResult.rawText)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (!mounted || _completed) return;
        candidate = textMatch?.displayName;
      }

      if (candidate == null || candidate.trim().isEmpty) {
        setState(() => _status = 'Lendo... mantenha a carta centralizada.');
        _resetCandidate();
        return;
      }

      final normalized = candidate.toLowerCase();
      if (_lastCandidate?.toLowerCase() == normalized) {
        _sameCandidateCount += 1;
      } else {
        _lastCandidate = candidate;
        _sameCandidateCount = 1;
      }

      setState(() {
        _status = _sameCandidateCount >= 2
            ? '$candidate detectada ✓'
            : 'Possível carta: $candidate — confirmando...';
      });

      if (_sameCandidateCount >= 2) {
        _completed = true;
        _scanTimer?.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        widget.onCardNameDetected(candidate);
      }
    } catch (_) {
      if (mounted && !_completed) {
        setState(() => _status = 'Lendo... ajuste o foco e a iluminação.');
      }
    } finally {
      _processing = false;
    }
  }

  void _resetCandidate() {
    _lastCandidate = null;
    _sameCandidateCount = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scanTimer?.cancel();
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && !_completed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _camera?.dispose();
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner automático')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!_initializing && camera != null && camera.value.isInitialized)
                      CameraPreview(camera)
                    else
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    IgnorePointer(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: .78,
                          heightFactor: .72,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_processing) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Não precisa tirar foto. O app tenta reconhecer primeiro pelo nome e, se necessário, pelo texto da carta.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
