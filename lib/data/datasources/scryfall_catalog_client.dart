import 'package:dio/dio.dart';

import '../../domain/entities/card_printing.dart';

class ScryfallCatalogCard {
  const ScryfallCatalogCard({
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
}

class ScryfallCatalogClient {
  ScryfallCatalogClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _headers = {
    'User-Agent': 'ManaPriceBR/0.1 (card catalog lookup)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  Future<List<String>> autocomplete(String query) async {
    final name = query.trim();
    if (name.length < 2) return const [];

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.scryfall.com/cards/autocomplete',
      queryParameters: {
        'q': name,
        'include_extras': true,
      },
      options: Options(
        headers: _headers,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) return const [];
    final rows = response.data!['data'];
    if (rows is! List) return const [];

    return rows
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .take(8)
        .toList(growable: false);
  }

  Future<ScryfallCatalogCard?> find(String query) async {
    final name = query.trim();
    if (name.isEmpty) return null;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.scryfall.com/cards/named',
      queryParameters: {'exact': name},
      options: Options(
        headers: _headers,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) return null;
    final data = response.data!;
    final canonicalName = data['name'] as String?;
    if (canonicalName == null || canonicalName.trim().isEmpty) return null;

    return ScryfallCatalogCard(
      name: canonicalName,
      imageUrl: _imageUrl(data),
    );
  }

  Future<List<CardPrinting>> printings(String exactName) async {
    final name = exactName.trim();
    if (name.isEmpty) return const [];

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.scryfall.com/cards/search',
      queryParameters: {
        'q': 'exact:"$name"',
        'unique': 'prints',
        'order': 'released',
        'dir': 'desc',
      },
      options: Options(
        headers: _headers,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) return const [];
    final rows = response.data!['data'];
    if (rows is! List) return const [];

    final result = <CardPrinting>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final card = Map<String, dynamic>.from(row);
      final canonicalName = card['name'] as String?;
      final setCode = card['set'] as String?;
      final setName = card['set_name'] as String?;
      final collectorNumber = card['collector_number']?.toString();
      if (canonicalName == null ||
          setCode == null ||
          setName == null ||
          collectorNumber == null) {
        continue;
      }

      result.add(CardPrinting(
        name: canonicalName,
        setCode: setCode,
        setName: setName,
        collectorNumber: collectorNumber,
        imageUrl: _imageUrl(card),
        foilAvailable: card['foil'] == true,
        nonfoilAvailable: card['nonfoil'] == true,
      ));
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
