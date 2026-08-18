import 'package:dio/dio.dart';

import '../../domain/entities/card_printing.dart';

class ScryfallCatalogCard {
  const ScryfallCatalogCard({
    required this.name,
    this.displayName,
    this.imageUrl,
  });

  final String name;
  final String? displayName;
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

    final results = <String>[];

    // Fast canonical/English autocomplete.
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/autocomplete',
        queryParameters: {
          'q': name,
          'include_extras': true,
        },
        options: _options,
      );
      if (response.statusCode == 200 && response.data != null) {
        final rows = response.data!['data'];
        if (rows is List) {
          for (final row in rows.whereType<String>()) {
            _addUnique(results, row);
          }
        }
      }
    } catch (_) {}

    // Multilingual fallback. Scryfall returns printed_name for localized cards.
    // We intentionally filter client-side so "Testemunha Eterna" can resolve
    // even though the canonical card name is Eternal Witness.
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/search',
        queryParameters: {
          'q': name,
          'include_multilingual': true,
          'include_extras': true,
          'unique': 'cards',
          'order': 'name',
        },
        options: _options,
      );
      if (response.statusCode == 200 && response.data != null) {
        final rows = response.data!['data'];
        if (rows is List) {
          final needle = _normalize(name);
          for (final row in rows) {
            if (row is! Map) continue;
            final card = Map<String, dynamic>.from(row);
            final printed = card['printed_name']?.toString().trim();
            final canonical = card['name']?.toString().trim();
            if (printed != null &&
                printed.isNotEmpty &&
                _normalize(printed).contains(needle)) {
              _addUnique(results, printed);
            }
            if (canonical != null &&
                canonical.isNotEmpty &&
                _normalize(canonical).contains(needle)) {
              _addUnique(results, canonical);
            }
            if (results.length >= 8) break;
          }
        }
      }
    } catch (_) {}

    return results.take(8).toList(growable: false);
  }

  Future<ScryfallCatalogCard?> find(String query) async {
    final name = query.trim();
    if (name.isEmpty) return null;

    // First try canonical exact lookup.
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/named',
        queryParameters: {'exact': name},
        options: _options,
      );
      if (response.statusCode == 200 && response.data != null) {
        return _cardFromJson(response.data!);
      }
    } catch (_) {}

    // Then resolve localized/printed names (Portuguese included).
    return _findLocalized(name);
  }

  Future<ScryfallCatalogCard?> _findLocalized(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/search',
        queryParameters: {
          'q': query,
          'include_multilingual': true,
          'include_extras': true,
          'unique': 'prints',
          'order': 'released',
          'dir': 'desc',
        },
        options: _options,
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final rows = response.data!['data'];
      if (rows is! List) return null;

      final needle = _normalize(query);
      Map<String, dynamic>? partial;
      for (final row in rows) {
        if (row is! Map) continue;
        final card = Map<String, dynamic>.from(row);
        final printed = card['printed_name']?.toString().trim();
        final canonical = card['name']?.toString().trim();
        if (printed != null && _normalize(printed) == needle) {
          return _cardFromJson(card);
        }
        if (canonical != null && _normalize(canonical) == needle) {
          return _cardFromJson(card);
        }
        if (partial == null &&
            ((printed != null && _normalize(printed).contains(needle)) ||
                (canonical != null && _normalize(canonical).contains(needle)))) {
          partial = card;
        }
      }
      return partial == null ? null : _cardFromJson(partial);
    } catch (_) {
      return null;
    }
  }

  Future<List<CardPrinting>> printings(String exactName) async {
    final input = exactName.trim();
    if (input.isEmpty) return const [];

    final resolved = await find(input);
    final name = resolved?.name ?? input;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.scryfall.com/cards/search',
      queryParameters: {
        'q': 'exact:"$name"',
        'unique': 'prints',
        'order': 'released',
        'dir': 'desc',
        'include_multilingual': true,
      },
      options: _options,
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

  Options get _options => Options(
        headers: _headers,
        validateStatus: (status) => status != null && status < 500,
      );

  static ScryfallCatalogCard? _cardFromJson(Map<String, dynamic> data) {
    final canonicalName = data['name'] as String?;
    if (canonicalName == null || canonicalName.trim().isEmpty) return null;
    final printedName = data['printed_name']?.toString();
    return ScryfallCatalogCard(
      name: canonicalName,
      displayName: printedName,
      imageUrl: _imageUrl(data),
    );
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

  static void _addUnique(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final normalized = _normalize(trimmed);
    if (values.any((item) => _normalize(item) == normalized)) return;
    values.add(trimmed);
  }

  static String _normalize(String value) {
    var text = value.toLowerCase().trim();
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }
    return text;
  }
}
