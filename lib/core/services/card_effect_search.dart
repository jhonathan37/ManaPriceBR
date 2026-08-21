import 'package:dio/dio.dart';

class CardEffectSearchResult {
  const CardEffectSearchResult({
    required this.name,
    required this.oracleText,
    required this.score,
    this.imageUrl,
    this.typeLine,
  });

  final String name;
  final String oracleText;
  final int score;
  final String? imageUrl;
  final String? typeLine;
}

class CardEffectSearch {
  CardEffectSearch({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _headers = {
    'User-Agent': 'ManaPriceBR/0.2 (effect text lookup)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  static const Map<String, String> _ptToOracle = {
    'sacrifica': 'sacrifice', 'sacrificar': 'sacrifice', 'sacrificio': 'sacrifice',
    'sacrifício': 'sacrifice', 'sacrifique': 'sacrifice',
    'criatura': 'creature', 'criaturas': 'creature',
    'comprar': 'draw', 'compra': 'draw', 'compre': 'draw',
    'destruir': 'destroy', 'destrua': 'destroy', 'destrói': 'destroy', 'destroi': 'destroy',
    'artefato': 'artifact', 'artefatos': 'artifact',
    'encantamento': 'enchantment', 'encantamentos': 'enchantment',
    'terreno': 'land', 'terrenos': 'land',
    'cemiterio': 'graveyard', 'cemitério': 'graveyard',
    'exilar': 'exile', 'exile': 'exile', 'exila': 'exile',
    'vida': 'life', 'mana': 'mana',
    'voar': 'flying', 'voa': 'flying',
    'atropelar': 'trample', 'atropela': 'trample',
    'vigilancia': 'vigilance', 'vigilância': 'vigilance',
    'toque': 'deathtouch', 'mortal': 'deathtouch',
    'vinculo': 'lifelink', 'vínculo': 'lifelink',
    'haste': 'haste', 'rapidez': 'haste',
    'ficha': 'token', 'fichas': 'token',
    'contador': 'counter', 'contadores': 'counter',
    'procure': 'search', 'procurar': 'search',
    'devolver': 'return', 'devolve': 'return', 'retorna': 'return',
    'oponente': 'opponent', 'oponentes': 'opponent',
    'controla': 'control', 'controle': 'control',
    'descartar': 'discard', 'descarta': 'discard', 'descarte': 'discard',
    'morrer': 'dies', 'morre': 'dies', 'morreu': 'dies',
    'entra': 'enters', 'entrar': 'enters',
    'campo': 'battlefield', 'batalha': 'battlefield',
    'virar': 'tap', 'vire': 'tap', 'desvirar': 'untap', 'desvire': 'untap',
    'dano': 'damage', 'dá': 'deals', 'causa': 'deals',
    'ganha': 'gain', 'ganhar': 'gain', 'perde': 'lose', 'perder': 'lose',
    'revela': 'reveal', 'revelar': 'reveal',
    'biblioteca': 'library', 'mao': 'hand', 'mão': 'hand',
  };

  Future<List<CardEffectSearchResult>> search(String description) async {
    final tokens = _oracleTokens(description);
    if (tokens.isEmpty) return const [];

    // 1) Exact intersection of remembered concepts.
    var rows = await _request(tokens.map((t) => 'o:"${_escape(t)}"').join(' '));

    // 2) Natural language is often approximate. If the strict query is empty,
    // search an OR pool and rank locally by how many remembered concepts match.
    if (rows.isEmpty && tokens.length > 1) {
      final orQuery = tokens.map((t) => 'o:"${_escape(t)}"').join(' OR ');
      rows = await _request('($orQuery)');
    }

    final results = <CardEffectSearchResult>[];
    final seen = <String>{};
    for (final row in rows) {
      final name = row['name']?.toString().trim();
      if (name == null || name.isEmpty || !seen.add(name.toLowerCase())) continue;
      final oracle = _oracleText(row);
      if (oracle.isEmpty) continue;
      final haystack = '${row['type_line'] ?? ''} $oracle'.toLowerCase();
      final score = tokens.where((token) => haystack.contains(token.toLowerCase())).length;
      if (score == 0) continue;
      results.add(CardEffectSearchResult(
        name: name,
        oracleText: oracle,
        score: score,
        typeLine: row['type_line']?.toString(),
        imageUrl: _imageUrl(row),
      ));
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.name.compareTo(b.name);
    });
    return results.take(20).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _request(String query) async {
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
        options: Options(headers: _headers, validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 200 || response.data == null) return const [];
      final data = response.data!['data'];
      if (data is! List) return const [];
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return const [];
    }
  }

  static List<String> _oracleTokens(String input) {
    final normalized = input.toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length < 3) return const [];
    const ignored = {
      'o','a','os','as','um','uma','uns','umas','de','da','do','das','dos','e','ou','que','se',
      'eu','ele','ela','meu','minha','para','por','com','sem','quando','tipo','faz','fazer','bicho',
      'carta','cartas','alvo','uma','cada','pode','voce','você','seu','sua'
    };
    final out = <String>[];
    for (final word in normalized.split(' ')) {
      if (word.length < 3 || ignored.contains(word)) continue;
      final token = _ptToOracle[word] ?? word;
      if (!out.contains(token)) out.add(token);
      if (out.length >= 7) break;
    }
    return out;
  }

  static String _oracleText(Map<String, dynamic> row) {
    final direct = row['oracle_text']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final faces = row['card_faces'];
    if (faces is List) {
      return faces.whereType<Map>()
          .map((f) => f['oracle_text']?.toString().trim() ?? '')
          .where((t) => t.isNotEmpty).join('\n');
    }
    return '';
  }

  static String? _imageUrl(Map<String, dynamic> row) {
    final images = row['image_uris'];
    if (images is Map) return images['small']?.toString() ?? images['normal']?.toString();
    final faces = row['card_faces'];
    if (faces is List && faces.isNotEmpty && faces.first is Map) {
      final faceImages = (faces.first as Map)['image_uris'];
      if (faceImages is Map) return faceImages['small']?.toString() ?? faceImages['normal']?.toString();
    }
    return null;
  }

  static String _escape(String value) => value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
