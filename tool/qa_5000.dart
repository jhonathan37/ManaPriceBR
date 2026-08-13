import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_client.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

Future<void> main(List<String> args) async {
  final limit = _intArg(args, 'limit', 5000).clamp(1, 5000);
  final priceLimit = _intArg(args, 'price-limit', limit).clamp(0, limit);
  final delayMs = _intArg(args, 'delay-ms', 1000).clamp(250, 5000);

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: const {
      'User-Agent': 'ManaPriceBR-QA/1.0 (catalog audit)',
      'Accept': 'application/json;q=0.9,*/*;q=0.8',
    },
  ));

  stdout.writeln('Carregando ate $limit cartas do catalogo Scryfall...');
  final selected = await _loadCatalogCards(dio, limit);
  if (selected.isEmpty) {
    stderr.writeln('Falha: nenhuma carta foi carregada do Scryfall.');
    exitCode = 2;
    return;
  }

  stdout.writeln('Cartas validas selecionadas: ${selected.length}');

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
        'Processadas ${i + 1}/${selected.length} | preco OK: $priceOk | sem preco: $priceMissing',
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

Future<List<_CardRow>> _loadCatalogCards(Dio dio, int limit) async {
  final selected = <_CardRow>[];
  final names = <String>{};

  String? nextUrl = 'https://api.scryfall.com/cards/search';
  Map<String, dynamic>? firstQuery = {
    'q': 'game:paper',
    'unique': 'cards',
    'order': 'name',
    'dir': 'asc',
    'include_extras': 'true',
  };

  while (nextUrl != null && selected.length < limit) {
    final response = await dio.get<Map<String, dynamic>>(
      nextUrl,
      queryParameters: firstQuery,
      options: Options(validateStatus: (status) => status != null && status < 500),
    );
    firstQuery = null;

    if (response.statusCode != 200 || response.data == null) {
      stderr.writeln('Falha ao carregar catalogo: HTTP ${response.statusCode}.');
      break;
    }

    final data = response.data!['data'];
    if (data is! List) break;

    for (final raw in data) {
      if (raw is! Map) continue;
      final card = Map<String, dynamic>.from(raw);
      final name = card['name']?.toString().trim();
      if (name == null || name.isEmpty || !names.add(name)) continue;
      final image = _imageUrl(card);
      if (image == null || image.isEmpty) continue;
      selected.add(_CardRow(name: name, imageUrl: image));
      if (selected.length >= limit) break;
    }

    final hasMore = response.data!['has_more'] == true;
    final candidate = response.data!['next_page']?.toString();
    nextUrl = hasMore && candidate != null && candidate.isNotEmpty ? candidate : null;

    if (nextUrl != null && selected.length < limit) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  return selected;
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
