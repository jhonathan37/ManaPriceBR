import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/services/card_ocr_reader.dart';
import '../../core/services/oracle_text_matcher.dart';
import '../../data/datasources/scryfall_catalog_client.dart';

class CardScannerPage extends StatefulWidget {
  const CardScannerPage({super.key, required this.onCardDetected});

  final ValueChanged<Map<String, String?>> onCardDetected;

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
  bool _torchOn = false;
  String? _error;
  String? _lastCandidate;
  String? _collectorHint;
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
    _torchOn = false;
    _resetCandidate();
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
        _status = 'Inicializando câmera...';
      });
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Nenhuma câmera disponível.');
      final rear = cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final selected = rear.isNotEmpty ? rear.first : cameras.first;
      final controller = CameraController(selected, ResolutionPreset.high, enableAudio: false);
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
      _scanTimer = Timer.periodic(const Duration(milliseconds: 1300), (_) => _scanOnce());
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.code == 'CameraAccessDenied'
            ? 'Permita o acesso à câmera nas configurações do aparelho para usar o scanner.'
            : 'Não foi possível abrir a câmera. Você ainda pode buscar a carta manualmente.';
        _status = 'Scanner indisponível';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Não foi possível iniciar o scanner. Você ainda pode buscar a carta manualmente.';
        _status = 'Scanner indisponível';
      });
    }
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      final next = !_torchOn;
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lanterna indisponível nesta câmera.')),
        );
      }
    }
  }

  Future<void> _scanOnce() async {
    final camera = _camera;
    if (_processing || _completed || camera == null || !camera.value.isInitialized) return;
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
        _collectorHint ??= ocrResult.collectorNumber;
      } else {
        _lastCandidate = candidate;
        _collectorHint = ocrResult.collectorNumber;
        _sameCandidateCount = 1;
      }

      setState(() {
        final collectorText = _collectorHint == null ? '' : ' • #${_collectorHint!}';
        _status = _sameCandidateCount >= 2
            ? '$candidate$collectorText detectada ✓'
            : 'Possível carta: $candidate$collectorText — confirmando...';
      });

      if (_sameCandidateCount >= 2) {
        _completed = true;
        _scanTimer?.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        widget.onCardDetected({
          'name': candidate,
          'collectorNumber': _collectorHint,
        });
      }
    } catch (_) {
      if (mounted && !_completed) {
        setState(() => _status = 'Lendo... ajuste o foco e a iluminação.');
      }
    } finally {
      _processing = false;
    }
  }

  void _manualSearch() {
    _completed = true;
    _scanTimer?.cancel();
    widget.onCardDetected({'name': null, 'collectorNumber': null});
  }

  void _resetCandidate() {
    _lastCandidate = null;
    _collectorHint = null;
    _sameCandidateCount = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scanTimer?.cancel();
      _camera?.dispose();
      _camera = null;
      _torchOn = false;
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
    final cameraReady = !_initializing && camera != null && camera.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner automático'),
        actions: [
          if (cameraReady)
            IconButton(
              tooltip: _torchOn ? 'Desligar lanterna' : 'Ligar lanterna',
              onPressed: _toggleTorch,
              icon: Icon(_torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded),
            ),
        ],
      ),
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
                    if (cameraReady)
                      CameraPreview(camera)
                    else if (_initializing)
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.no_photography_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              const Text('Câmera indisponível', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    if (cameraReady)
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
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _initializeCamera,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar câmera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _manualSearch,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Buscar manualmente'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _manualSearch,
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Prefiro digitar o nome da carta'),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'O app tenta reconhecer nome, texto e número de coleção para chegar na impressão correta.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
