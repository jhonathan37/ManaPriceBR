import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'card_name_parser.dart';

class CardOcrResult {
  const CardOcrResult({
    required this.rawText,
    this.cardName,
    this.collectorNumber,
  });

  final String rawText;
  final String? cardName;
  final String? collectorNumber;
}

class CardOcrReader {
  CardOcrReader({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<CardOcrResult> read(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final name = CardNameParser.clean(recognized.text);
    return CardOcrResult(
      rawText: recognized.text,
      cardName: name.isEmpty ? null : name,
      collectorNumber: _collectorHint(recognized.text),
    );
  }

  Future<String?> readCardName(String imagePath) async {
    final result = await read(imagePath);
    return result.cardName;
  }

  String? _collectorHint(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final tail = lines.length > 7 ? lines.sublist(lines.length - 7) : lines;

    for (final line in tail.reversed) {
      final slash = RegExp(r'\b(\d{1,4}[a-zA-Z]?)[\s]*/[\s]*\d{1,4}\b')
          .firstMatch(line);
      if (slash != null) return slash.group(1);
    }
    for (final line in tail.reversed) {
      final standalone = RegExp(r'\b(\d{2,4}[a-zA-Z]?)\b').firstMatch(line);
      if (standalone != null) return standalone.group(1);
    }
    return null;
  }

  Future<void> dispose() => _recognizer.close();
}
