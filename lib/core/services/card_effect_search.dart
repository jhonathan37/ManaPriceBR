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

  static const _headers = {'User-Agent':'ManaPriceBR/0.2 (natural language card discovery)','Accept':'application/json;q=0.9,*/*;q=0.8'};

  static const Map<String,String> _ptToOracle={
    'sacrifica':'sacrifice','sacrificar':'sacrifice','sacrificio':'sacrifice','sacrifício':'sacrifice','sacrifique':'sacrifice',
    'criatura':'creature','criaturas':'creature','comprar':'draw','compra':'draw','compre':'draw','comprando':'draw',
    'destruir':'destroy','destrua':'destroy','destrói':'destroy','destroi':'destroy','artefato':'artifact','artefatos':'artifact',
    'encantamento':'enchantment','encantamentos':'enchantment','terreno':'land','terrenos':'land','cemiterio':'graveyard','cemitério':'graveyard',
    'exilar':'exile','exila':'exile','vida':'life','mana':'mana','voar':'flying','voa':'flying','atropelar':'trample','atropela':'trample',
    'vigilancia':'vigilance','vigilância':'vigilance','haste':'haste','rapidez':'haste','ficha':'token','fichas':'token',
    'contador':'counter','contadores':'counter','procure':'search','procurar':'search','devolver':'return','devolve':'return','retorna':'return',
    'oponente':'opponent','oponentes':'opponent','controla':'control','controle':'control','descartar':'discard','descarta':'discard','descarte':'discard',
    'morrer':'dies','morre':'dies','morreu':'dies','morrendo':'dies','entra':'enters','entrar':'enters','campo':'battlefield','batalha':'battlefield',
    'virar':'tap','vire':'tap','desvirar':'untap','desvire':'untap','dano':'damage','causa':'deals','ganha':'gain','ganhar':'gain','perde':'lose','perder':'lose',
    'revela':'reveal','revelar':'reveal','biblioteca':'library','mao':'hand','mão':'hand','equipar':'equip','equipamento':'equipment',
    'copia':'copy','copiar':'copy','magica':'spell','mágica':'spell','instantanea':'instant','instantânea':'instant','feitico':'sorcery','feitiço':'sorcery',
    'atacar':'attack','ataca':'attacks','bloquear':'block','bloqueia':'blocks','marcador':'counter','marcadores':'counter','tutor':'search',
    'recupera':'return','recuperar':'return','ressuscita':'return','ressuscitar':'return','gera':'add','gerar':'add','adiciona':'add','adicionar':'add'
  };
  static const Map<String,String> _colorWords={'branca':'w','branco':'w','azul':'u','preta':'b','preto':'b','vermelha':'r','vermelho':'r','verde':'g'};
  static const Map<String,String> _typeWords={'criatura':'creature','criaturas':'creature','artefato':'artifact','artefatos':'artifact','encantamento':'enchantment','encantamentos':'enchantment','terreno':'land','terrenos':'land','planeswalker':'planeswalker','instantanea':'instant','instantânea':'instant','feitico':'sorcery','feitiço':'sorcery','batalha':'battle'};

  Future<List<CardEffectSearchResult>> search(String description) async {
    final intent=_parseIntent(description);
    if(intent.oracleTokens.isEmpty&&intent.filters.isEmpty)return const[];
    final strict=[...intent.filters,...intent.oracleTokens.map((t)=>'o:"${_escape(t)}"')];
    var rows=await _request(strict.join(' '));
    if(rows.isEmpty&&intent.oracleTokens.length>1){
      final orText=intent.oracleTokens.map((t)=>'o:"${_escape(t)}"').join(' OR ');
      rows=await _request([...intent.filters,'($orText)'].join(' '));
    }
    final results=<CardEffectSearchResult>[]; final seen=<String>{};
    for(final row in rows){
      final name=row['name']?.toString().trim(); if(name==null||name.isEmpty||!seen.add(name.toLowerCase()))continue;
      final oracle=_oracleText(row); final typeLine=row['type_line']?.toString()??''; final hay='$typeLine $oracle'.toLowerCase();
      var score=0;
      for(final token in intent.oracleTokens){if(hay.contains(token.toLowerCase()))score+=3;}
      for(final phrase in intent.semanticPhrases){if(hay.contains(phrase))score+=5;}
      if(intent.oracleTokens.isNotEmpty&&score==0)continue;
      results.add(CardEffectSearchResult(name:name,oracleText:oracle,score:score,typeLine:typeLine,imageUrl:_imageUrl(row)));
    }
    results.sort((a,b){final s=b.score.compareTo(a.score);return s!=0?s:a.name.compareTo(b.name);});
    return results.take(30).toList(growable:false);
  }

  Future<List<Map<String,dynamic>>> _request(String query) async {
    if(query.trim().isEmpty)return const[];
    try{final response=await _dio.get<Map<String,dynamic>>('https://api.scryfall.com/cards/search',queryParameters:{'q':query,'unique':'cards','order':'edhrec','dir':'asc','include_multilingual':true},options:Options(headers:_headers,validateStatus:(s)=>s!=null&&s<500));if(response.statusCode!=200||response.data==null)return const[];final data=response.data!['data'];if(data is! List)return const[];return data.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}catch(_){return const[];}
  }

  static _SearchIntent _parseIntent(String input){
    final normalized=input.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N} ]',unicode:true),' ').replaceAll(RegExp(r'\s+'),' ').trim();
    if(normalized.length<2)return const _SearchIntent([],[],[]);
    final words=normalized.split(' '); final filters=<String>[]; final colors=<String>{}; final explicitTypes=<String>{};
    for(final w in words){final c=_colorWords[w];if(c!=null)colors.add(c);final t=_typeWords[w];if(t!=null)explicitTypes.add(t);}
    if(colors.isNotEmpty)filters.add('c:${colors.join()}');
    final describesCard=words.contains('carta')||words.contains('bicho')||words.contains('permanente')||normalized.startsWith('criatura ')||normalized.startsWith('artefato ')||normalized.startsWith('encantamento ');
    if(describesCard&&explicitTypes.length==1)filters.add('t:${explicitTypes.first}');
    const ignored={'o','a','os','as','um','uma','uns','umas','de','da','do','das','dos','e','ou','que','se','eu','ele','ela','meu','minha','para','por','com','sem','quando','tipo','faz','fazer','bicho','carta','cartas','alvo','cada','pode','voce','você','seu','sua','tenha','tem','quero','procuro','achar','ache','alguma','algum','coisa'};
    final tokens=<String>[];
    for(final w in words){if(w.length<3||ignored.contains(w)||_colorWords.containsKey(w))continue;final token=_ptToOracle[w]??w;if(!tokens.contains(token))tokens.add(token);if(tokens.length>=10)break;}
    final phrases=<String>[];
    void phrase(bool test,String value){if(test&&!phrases.contains(value))phrases.add(value);}
    phrase((normalized.contains('quando morre')||normalized.contains('quando morrer')),'when');
    phrase(normalized.contains('entra no campo')||normalized.contains('entrar no campo'),'enters the battlefield');
    phrase(normalized.contains('volta do cemiterio')||normalized.contains('volta do cemitério')||normalized.contains('devolve do cemiterio')||normalized.contains('devolve do cemitério'),'from your graveyard');
    phrase(normalized.contains('compra uma carta')||normalized.contains('compre uma carta'),'draw a card');
    phrase(normalized.contains('sacrifica uma criatura')||normalized.contains('sacrifique uma criatura'),'sacrifice a creature');
    phrase(normalized.contains('destroi criatura')||normalized.contains('destrói criatura')||normalized.contains('destrua criatura'),'destroy target creature');
    phrase(normalized.contains('ganha vida')||normalized.contains('ganhar vida'),'gain life');
    phrase(normalized.contains('perde vida')||normalized.contains('perder vida'),'lose life');
    return _SearchIntent(tokens,filters,phrases);
  }

  static String _oracleText(Map<String,dynamic> row){final d=row['oracle_text']?.toString().trim();if(d!=null&&d.isNotEmpty)return d;final f=row['card_faces'];if(f is List)return f.whereType<Map>().map((x)=>x['oracle_text']?.toString().trim()??'').where((t)=>t.isNotEmpty).join('\n');return '';}
  static String? _imageUrl(Map<String,dynamic> row){final i=row['image_uris'];if(i is Map)return i['small']?.toString()??i['normal']?.toString();final f=row['card_faces'];if(f is List&&f.isNotEmpty&&f.first is Map){final x=(f.first as Map)['image_uris'];if(x is Map)return x['small']?.toString()??x['normal']?.toString();}return null;}
  static String _escape(String value)=>value.replaceAll(r'\',r'\\').replaceAll('"',r'\"');
}
class _SearchIntent{const _SearchIntent(this.oracleTokens,this.filters,this.semanticPhrases);final List<String> oracleTokens;final List<String> filters;final List<String> semanticPhrases;}
