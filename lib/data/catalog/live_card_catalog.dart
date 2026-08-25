import 'package:dio/dio.dart';

import '../../domain/entities/card_printing.dart';
import '../datasources/scryfall_catalog_client.dart';

/// Live catalog facade.
///
/// Nothing is bundled here: autocomplete, card resolution and printings are
/// requested from Scryfall at use time. That means newly released cards and
/// sets become available without publishing a new app version.
class LiveCardCatalog {
  LiveCardCatalog({Dio? dio, ScryfallCatalogClient? base})
      : _dio = dio ?? Dio(),
        _base = base ?? ScryfallCatalogClient();

  final Dio _dio;
  final ScryfallCatalogClient _base;

  static const _headers = {
    'User-Agent': 'ManaPriceBR/0.3 (live catalog lookup)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  Future<List<String>> autocomplete(String query) => _base.autocomplete(query);

  Future<ScryfallCatalogCard?> find(String query) => _base.find(query);

  Future<List<CardPrinting>> printings(String exactName) async {
    final input = exactName.trim();
    if (input.isEmpty) return const [];

    final resolved = await _base.find(input);
    final canonicalName = resolved?.name ?? input;

    var nextPage = 'https://api.scryfall.com/cards/search';
    Map<String, dynamic>? queryParameters = {
      'q': 'exact:"$canonicalName"',
      'unique': 'prints',
      'order': 'released',
      'dir': 'desc',
      'include_multilingual': true,
    };

    final result = <CardPrinting>[];
    final seen = <String>{};

    // Scryfall paginates search results. Following next_page prevents older
    // printings from disappearing and automatically includes future sets.
    for (var page = 0; page < 12; page++) {
      final response = await _dio.get<Map<String, dynamic>>(
        nextPage,
        queryParameters: queryParameters,
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200 || response.data == null) break;
      final data = response.data!;
      final rows = data['data'];
      if (rows is! List) break;

      for (final row in rows) {
        if (row is! Map) continue;
        final card = Map<String, dynamic>.from(row);
        final name = card['name'] as String?;
        final setCode = card['set'] as String?;
        final setName = card['set_name'] as String?;
        final collectorNumber = card['collector_number']?.toString();
        if (name == null ||
            setCode == null ||
            setName == null ||
            collectorNumber == null) {
          continue;
        }

        final id = '${setCode.toLowerCase()}:$collectorNumber';
        if (!seen.add(id)) continue;

        result.add(CardPrinting(
          name: name,
          setCode: setCode,
          setName: setName,
          collectorNumber: collectorNumber,
          imageUrl: _imageUrl(card),
          foilAvailable: card['foil'] == true,
          nonfoilAvailable: card['nonfoil'] == true,
        ));
      }

      if (data['has_more'] != true) break;
      final next = data['next_page']?.toString().trim();
      if (next == null || next.isEmpty) break;
      nextPage = next;
      queryParameters = null;
    }

    return result;
  }

  static String? _imageUrl(Map<String, dynamic> data) {
    final imageUris = data['image_uris'];
    if (imageUris is Map) {
      return imageUris['normal'] as String? ?? imageUris['small'] as String?;
    }

    final faces = data['card_faces'];
    if (faces is List && faces.isNotEmpty && faces.first is Map) {
      final firstFace = faces.first as Map;
      final faceImages = firstFace['image_uris'];
      if (faceImages is Map) {
        return faceImages['normal'] as String? ?? faceImages['small'] as String?;
      }
    }
    return null;
  }
}
