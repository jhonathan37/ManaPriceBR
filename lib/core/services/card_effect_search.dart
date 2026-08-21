import 'package:dio/dio.dart';

class CardEffectSearchResult {
  const CardEffectSearchResult({required this.name, required this.oracleText, required this.score, this.imageUrl, this.typeLine});
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
    'User-Agent': 'ManaPriceBR/0.2 (natural language card discovery)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  static const Map<String, String> _ptToOracle = {
    'sacrifica':'sacrifice','sacrificar':'sacrifice','sacrificio':'sacrifice','sacrifício':'sacrifice','sacrifique':'sacrifice',
    'criatura':'creature','criaturas':'creature','comprar':'draw','compra':'draw','compre':'draw',
    'destruir':'destroy','destrua':'destroy','destrói':'destroy','destroi':'destroy','artefato':'artifact','artefatos':'artifact',
    'encantamento':'enchantment','encantamentos':'enchantment','terreno':'land','terrenos':'land','cemiterio':'graveyard','cemitério':'graveyard',
    'exilar':'exile','exila':'exile','vida':'life','mana':'mana','voar':'flying','voa':'flying','atropelar':'trample','atropela':'trample',
    'vigilancia':'vigilance','vigilância':'vigilance','haste':'haste','rapidez':'haste','ficha':'token','fichas':'token',
    'contador':'counter','contadores':'counter','procure':'search','procurar':'search','devolver':'return','devolve':'return','retorna':'return',
    'oponente':'opponent','oponentes':'opponent','controla':'control','controle':'control','descartar':'discard','descarta':'discard','descarte':'discard',
    'morrer':'dies','morre':'dies','morreu':'dies','entra':'enters','entrar':'enters','campo':'battlefield','batalha':'battlefield',
    'virar':'tap','vire':'tap','desvirar':'untap','desvire':'untap','dano':'damage','causa':'deals','ganha':'gain','ganhar':'gain','perde':'lose','perder':'lose',
    'revela':'reveal','revelar':'reveal','biblioteca':'library','mao':'hand','mão':'hand','equipar':'equip','equipamento':'equipment',
    'copia':'copy','copiar':'copy','magica':'spell','mágica':'spell','instantanea':'instant','instantânea':'instant','feitico':'sorcery','feitiço':'sorcery',
    'atacar':'attack','ataca':'attacks','bloquear':'block','bloqueia':'blocks','marcador':'counter','marcadores':'counter',
  };

  static const Map<String, String> _colorWords = {
    'branca':'w','branco':'w','azul':'u','preta':'b','preto':'b','vermelha':'r','vermelho':'r','verde':'g',
  };
  static const Map<String, String> _typeWords = {
    'criatura':'creature','criaturas':'creature','artefato':'artifact','artefatos':'artifact','encantamento':'enchantment',
    'encantamentos':'enchantment','terreno':'land','terrenos':'land','planeswalker':'planeswalker','instantanea':'instant','instantânea':'instant',
    'feitico':'sorcery','feitiço':'sorcery','batalha':'battle',
  };

  Future<List<CardEffectSearchResult>> search(String description) async {
    final intent = _parseIntent(description);
    if (intent.oracleTokens.isEmpty && intent.filters.isEmpty) return const [];

    final strictParts = <String>[
      ...intent.filters,
      ...intent.oracleTokens.map((t) => 'o:"${_escape(t)}"'),
    ];
    var rows = await _request(strictParts.join(' '));

    // Relax only the remembered rules text, never explicit color/type filters.
    if (rows.isEmpty && intent.oracleTokens.length > 1) {
      final orText = intent.oracleTokens.map((t) => 'o:"${_escape(t)}"').join(' OR ');
      rows = await _request([...intent.filters, '($orText)'].join(' '));
    }

    final results = <CardEffectSearchResult>[];
    final seen = <String>{};
    for (final row in rows) {
      final name = row['name']?.toString().trim();
      if (name == null || name.isEmpty || !seen.add(name.toLowerCase())) continue;
      final oracle = _oracleText(row);
      final typeLine = row['type_line']?.toString() ?? '';
      final haystack = '$typeLine $oracle'.toLowerCase();
      final score = intent.oracleTokens.where((t) => haystack.contains(t.toLowerCase())).length;
      if (intent.oracleTokens.isNotEmpty && score == 0) continue;
      results.add(CardEffectSearchResult(name:name, oracleText:oracle, score:score, typeLine:typeLine, imageUrl:_imageUrl(row)));
    }
    results.sort((a,b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : a.name.compareTo(b.name);
    });
    return results.take(30).toList(growable:false);
  }

  Future<List<Map<String,dynamic>>> _request(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final response = await _dio.get<Map<String,dynamic>>('https://api.scryfall.com/cards/search',
        queryParameters:{'q':query,'unique':'cards','order':'edhrec','dir':'asc','include_multilingual':true},
        options:Options(headers:_headers, validateStatus:(s)=>s!=null && s<500));
      if (response.statusCode != 200 || response.data == null) return const [];
      final data=response.data!['data'];
      if (data is! List) return const [];
      return data.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    } catch (_) { return const []; }
  }

  static _SearchIntent _parseIntent(String input) {
    final normalized=input.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N} ]',unicode:true),' ').replaceAll(RegExp(r'\s+'),' ').trim();
    if (normalized.length < 2) return const _SearchIntent([],[]);
    final words=normalized.split(' ');
    final filters=<String>[];
    final colors=<String>{};
    final explicitTypes=<String>{};
    for (final w in words) {
      final color=_colorWords[w]; if (color!=null) colors.add(color);
      final type=_typeWords[w]; if (type!=null) explicitTypes.add(type);
    }
    if (colors.isNotEmpty) filters.add('c:${colors.join()}');
    // Treat type as an explicit filter only when phrasing suggests the card itself.
    final describesCard = words.contains('carta') || words.contains('bicho') || words.contains('permanente') ||
        normalized.startsWith('criatura ') || normalized.startsWith('artefato ') || normalized.startsWith('encantamento ');
    if (describesCard && explicitTypes.length == 1) filters.add('t:${explicitTypes.first}');

    const ignored={'o','a','os','as','um','uma','uns','umas','de','da','do','das','dos','e','ou','que','se','eu','ele','ela','meu','minha','para','por','com','sem','quando','tipo','faz','fazer','bicho','carta','cartas','alvo','cada','pode','voce','você','seu','sua','tenha','tem','quero','procuro','achar','ache'};
    final tokens=<String>[];
    for (final w in words) {
      if (w.length<3 || ignored.contains(w) || _colorWords.containsKey(w)) continue;
      final token=_ptToOracle[w] ?? w;
      if (!tokens.contains(token)) tokens.add(token);
      if (tokens.length>=8) break;
    }
    return _SearchIntent(tokens,filters);
  }

  static String _oracleText(Map<String,dynamic> row) {
    final direct=row['oracle_text']?.toString().trim(); if (direct!=null && direct.isNotEmpty) return direct;
    final faces=row['card_faces']; if (faces is List) return faces.whereType<Map>().map((f)=>f['oracle_text']?.toString().trim()??'').where((t)=>t.isNotEmpty).join('\n');
    return '';
  }
  static String? _imageUrl(Map<String,dynamic> row) {
    final images=row['image_uris']; if(images is Map) return images['small']?.toString()??images['normal']?.toString();
    final faces=row['card_faces']; if(faces is List && faces.isNotEmpty && faces.first is Map){final i=(faces.first as Map)['image_uris']; if(i is Map)return i['small']?.toString()??i['normal']?.toString();} return null;
  }
  static String _escape(String value)=>value.replaceAll(r'\',r'\\').replaceAll('"',r'\"');
}

class _SearchIntent {
  const _SearchIntent(this.oracleTokens,this.filters);
  final List<String> oracleTokens;
  final List<String> filters;
}
