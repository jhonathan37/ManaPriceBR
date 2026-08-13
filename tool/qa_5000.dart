import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_client.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

/// Auditor de qualidade do ManaPriceBR.
///
/// - Baixa o bulk `default_cards` do Scryfall uma única vez.
/// - Seleciona até 5.000 nomes únicos com imagem.
/// - Valida nome + imagem sem fazer 5.000 requests individuais ao Scryfall.
/// - Opcionalmente consulta a LigaMagic, de forma sequencial e espaçada,
///   registrando sucesso/falha sem inventar preço.
///
/// Uso:
///   dart run tool/qa_5000.dart --limit=5000 --price-limit=100 --delay-ms=700
///
/// Para uma auditoria completa de preço, use --price-limit=5000. Isso é
/// propositalmente lento para reduzir 403/429 e não sobrecarregar a LigaMagic.
Future<void> main(List<String> args) async {
  final limit = _intArg(args, 'limit', 5000).clamp(1, 5000);
  final priceLimit = _intArg(args, 'price-limit', 100).clamp(0, limit);
  final delayMs = _intArg(args, 'delay-ms', 700).clamp(250, 5000);

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: const {
      'User-Agent': 'ManaPriceBR-QA/1.0',
      'Accept': 'application/json',
    },
  ));

  stdout.writeln('Obtendo bulk data do Scryfall...');
  final bulkMeta = await dio.get<Map<String, dynamic>>(
    'https://api.scryfall.com/bulk-data/default-cards',
  );
  final downloadUri = bulkMeta.data?['download_uri'] as String?;
  if (downloadUri == null) {
    stderr.writeln('Falha: Scryfall não retornou download_uri.');
    exitCode = 2;
    return;
  }

  final bulkResp = await dio.get<String>(
    downloadUri,
    options: Options(responseType: ResponseType.plain),
  );
  final decoded = jsonDecode(bulkResp.data ?? '[]');
  if (decoded is! List) {
    stderr.writeln('Falha: bulk do Scryfall não é uma lista.');
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

  stdout.writeln('Cartas válidas selecionadas: ${selected.length}');

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
      if (i + 1 < priceLimit) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
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

    if ((i + 1) % 100 == 0 || i + 1 == selected.length) {
      stdout.writeln(
        'Processadas ${i + 1}/${selected.length} | preço OK: $priceOk | sem preço: $priceMissing',
      );
    }
  }

  await sink.flush();
  await sink.close();

  final summary = {
    'cards_requested': limit,
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
  if (images is Map) {
    return images['normal']?.toString() ?? images['small']?.toString();
  }
  final faces = card['card_faces'];
  if (faces is List && faces.isNotEmpty && faces.first is Map) {
    final first = faces.first as Map;
    final faceImages = first['image_uris'];
    if (faceImages is Map) {
      return faceImages['normal']?.toString() ?? faceImages['small']?.toString();
    }
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
