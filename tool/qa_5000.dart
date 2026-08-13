import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_client.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

/// Auditor sequencial do ManaPriceBR.
/// Valida ate 5.000 cartas, UMA POR VEZ, e so termina quando todas forem
/// processadas. Nome/imagem vem do bulk do Scryfall; preco e consultado
/// sequencialmente na LigaMagic, com pausa entre cartas.
Future<void> main(List<String> args) async {
  final limit = _intArg(args, 'limit', 5000).clamp(1, 5000);
  final priceLimit = _intArg(args, 'price-limit', limit).clamp(0, limit);
  final delayMs = _intArg(args, 'delay-ms', 1000).clamp(500, 10000);

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 90),
    headers: const {
      'User-Agent': 'ManaPriceBR-QA/1.1',
      'Accept': 'application/json',
    },
  ));

  stdout.writeln('Obtendo indice de bulk data do Scryfall...');
  final bulkIndex = await dio.get<dynamic>('https://api.scryfall.com/bulk-data');
  final root = bulkIndex.data;
  final data = root is Map ? root['data'] : null;
  if (data is! List) {
    stderr.writeln('Falha: indice bulk do Scryfall nao retornou data[].');
    exitCode = 2;
    return;
  }

  String? downloadUri;
  for (final raw in data) {
    if (raw is Map && raw['type']?.toString() == 'default_cards') {
      downloadUri = raw['download_uri']?.toString();
      break;
    }
  }
  if (downloadUri == null || downloadUri.isEmpty) {
    stderr.writeln('Falha: dataset default_cards nao encontrado no indice bulk.');
    exitCode = 2;
    return;
  }

  stdout.writeln('Baixando default_cards...');
  final bulkResp = await dio.get<String>(downloadUri,
      options: Options(responseType: ResponseType.plain));
  final decoded = jsonDecode(bulkResp.data ?? '[]');
  if (decoded is! List) {
    stderr.writeln('Falha: bulk do Scryfall nao e uma lista.');
    exitCode = 2;
    return;
  }

  final selected = <_CardRow>[];
  final names = <String>{};
  for (final raw in decoded) {
    if (raw is! Map) continue;
    final card = Map<String, dynamic>.from(raw);
    final name = card['name']?.toString().trim();
    if (name == null || name.isEmpty || !names.add(name)) continue;
    final image = _imageUrl(card);
    if (image == null || image.isEmpty) continue;
    selected.add(_CardRow(name: name, imageUrl: image));
    if (selected.length >= limit) break;
  }

  stdout.writeln('Cartas selecionadas: ${selected.length}. Iniciando teste UMA POR VEZ.');
  final liga = LigaMagicScrapeClient();
  var priceOk = 0;
  var priceMissing = 0;

  final output = File('qa_5000_report.csv');
  final sink = output.openWrite();
  sink.writeln('index,name,image_ok,image_url,price_checked,price_ok,price_brl,status');

  for (var i = 0; i < selected.length; i++) {
    final row = selected[i];
    var checked = false;
    var priceOkRow = false;
    double? price;
    var status = 'catalog_ok';

    stdout.writeln('[${i + 1}/${selected.length}] ${row.name}');
    if (i < priceLimit) {
      checked = true;
      try {
        final result = await liga.lookup(PriceLookupRequest(cardName: row.name));
        if (result != null && result.response.referencePrice > 0) {
          price = result.response.referencePrice;
          priceOkRow = true;
          priceOk++;
          status = 'price_ok';
        } else {
          priceMissing++;
          status = 'price_not_returned';
        }
      } catch (error) {
        priceMissing++;
        status = 'price_error:${error.runtimeType}';
      }
    }

    sink.writeln([
      i + 1,
      _csv(row.name),
      true,
      _csv(row.imageUrl),
      checked,
      priceOkRow,
      price?.toStringAsFixed(2) ?? '',
      _csv(status),
    ].join(','));
    await sink.flush();

    if (i + 1 < priceLimit) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }

  await sink.close();
  final summary = {
    'cards_requested': limit,
    'cards_processed_sequentially': selected.length,
    'cards_with_name_and_image': selected.length,
    'price_checks_requested': priceLimit,
    'price_ok': priceOk,
    'price_not_returned_or_error': priceMissing,
    'price_success_percent': priceLimit == 0 ? 0 : (priceOk * 100 / priceLimit),
    'report': output.path,
  };
  await File('qa_5000_summary.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
}

int _intArg(List<String> args, String name, int fallback) {
  final prefix = '--$name=';
  final match = args.where((arg) => arg.startsWith(prefix)).firstOrNull;
  return int.tryParse(match?.substring(prefix.length) ?? '') ?? fallback;
}

String? _imageUrl(Map<String, dynamic> card) {
  final images = card['image_uris'];
  if (images is Map) return images['normal']?.toString() ?? images['small']?.toString();
  final faces = card['card_faces'];
  if (faces is List && faces.isNotEmpty && faces.first is Map) {
    final faceImages = (faces.first as Map)['image_uris'];
    if (faceImages is Map) return faceImages['normal']?.toString() ?? faceImages['small']?.toString();
  }
  return null;
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

class _CardRow {
  const _CardRow({required this.name, required this.imageUrl});
  final String name;
  final String imageUrl;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
