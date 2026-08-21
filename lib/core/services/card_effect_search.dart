import 'package:dio/dio.dart';

class CardEffectSearchResult {
  const CardEffectSearchResult({
    required this.name,
    required this.oracleText,
    this.imageUrl,
    this.typeLine,
  });

  final String name;
  final String oracleText;
  final String? imageUrl;
  final String? typeLine;
}

class CardEffectSearch {
  CardEffectSearch({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _headers = {
    'User-Agent': 'ManaPriceBR/0.1 (effect text lookup)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  static const Map<String, String> _ptToOracle = {
    'sacrifica': 'sacrifice',
    'sacrificar': 'sacrifice',
    'sacrificio': 'sacrifice',
    'sacrifício': 'sacrifice',
    'sacrifique': 'sacrifice',
    'criatura': 'creature',
    'criaturas': 'creature',
    'comprar': 'draw',
    'compra': 'draw',
    'compre': 'draw',
    'carta': 'card',
    'cartas': 'card',
    'destruir': 'destroy',
    'destrua': 'destroy',
    'destrói': 'destroy',
    'destroi': 'destroy',
    'artefato': 'artifact',
    'artefatos': 'artifact',
    'encantamento': 'enchantment',
    'encantamentos': 'enchantment',
    'terreno': 'land',
    'terrenos': 'land',
    'cemiterio': 'graveyard',
    'cemitério': 'graveyard',
    'exilar': 'exile',
    'exile': 'exile',
    'exila': 'exile',
    'vida': 'life',
    'mana': 'mana',
    'voar': 'flying',
    'voa': 'flying',
    'voar-se': 'flying',
    'atropelar': 'trample',
    'atropela': 'trample',
    'vigilancia': 'vigilance',
    'vigilância': 'vigilance',
    'toque': 'deathtouch',
    'mortal': 'deathtouch',
    'vinculo': 'lifelink',
    'vínculo': 'lifelink',
    'haste': 'haste',
    'rapidez': 'haste',
    'ficha': 'token',
    'fichas': 'token',
    'contador': 'counter',
    'contadores': 'counter',
    'procure': 'search',
    'procurar': 'search',
    'devolver': 'return',
    'devolve': 'return',
    'retorna': 'return',
    'oponente': 'opponent',
    'oponentes': 'opponent',
    'controla': 'control',
    'controle': 'control',
  };

  Future<List<CardEffectSearchResult>> search(String description) async {
    final raw = description.trim();
    if (raw.length < 3) return const [];

    final tokens = _oracleTokens(raw);
    if (tokens.isEmpty) return const [];

    // Start specific (AND between concepts). If that yields nothing, relax by
    // keeping only the most meaningful concepts. This lets natural queries
    // like "sacrifica criatura compra carta" work without exact wording.
    for (final count in <int>[tokens.length, tokens.length.clamp(1, 3)]) {
      final selected = tokens.take(count).toList(growable: false);
      final results = await _run(selected);
      if (results.isNotEmpty) return results;
    }
    return const [];
  }

  Future<List<CardEffectSearchResult>> _run(List<String> tokens) async {
    if (tokens.isEmpty) return const [];
    final query = tokens.map((t) => 'oracle:"${_escape(t)}"').join(' ');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/search',
        queryParameters: {
          'q': query,
          'unique': 'cards',
          'order': 'edhrec',
          'dir': 'asc',
          'include_multilingual': true,
        },
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200 || response.data == null) return const [];
      final rows = response.data!['data'];
      if (rows is! List) return const [];

      final results = <CardEffectSearchResult>[];
      final seen = <String>{};
      for (final raw in rows) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final name = row['name']?.toString().trim();
        if (name == null || name.isEmpty || !seen.add(name.toLowerCase())) continue;
        final oracle = _oracleText(row);
        if (oracle.isEmpty) continue;
        results.add(
          CardEffectSearchResult(
            name: name,
            oracleText: oracle,
            typeLine: row['type_line']?.toString(),
            imageUrl: _imageUrl(row),
          ),
        );
        if (results.length >= 12) break;
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  static List<String> _oracleTokens(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = normalized.split(' ');
    const ignored = {
      'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas', 'de', 'da', 'do',
      'das', 'dos', 'e', 'ou', 'que', 'se', 'eu', 'ele', 'ela', 'meu', 'minha',
      'para', 'por', 'com', 'sem', 'quando', 'tipo', 'faz', 'fazer', 'bicho',
      'carta', 'cartas',
    };
    final out = <String>[];
    for (final word in words) {
      if (word.length < 3 || ignored.contains(word)) continue;
      final token = _ptToOracle[word] ?? word;
      if (!out.contains(token)) out.add(token);
      if (out.length >= 5) break;
    }
    return out;
  }

  static String _oracleText(Map<String, dynamic> row) {
    final direct = row['oracle_text']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final faces = row['card_faces'];
    if (faces is List) {
      return faces
          .whereType<Map>()
          .map((f) => f['oracle_text']?.toString().trim() ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n');
    }
    return '';
  }

  static String? _imageUrl(Map<String, dynamic> row) {
    final images = row['image_uris'];
    if (images is Map) {
      return images['small']?.toString() ?? images['normal']?.toString();
    }
    final faces = row['card_faces'];
    if (faces is List && faces.isNotEmpty && faces.first is Map) {
      final images = (faces.first as Map)['image_uris'];
      if (images is Map) {
        return images['small']?.toString() ?? images['normal']?.toString();
      }
    }
    return null;
  }

  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
