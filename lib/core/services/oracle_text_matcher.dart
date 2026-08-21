import 'package:dio/dio.dart';

class OracleTextMatch {
  const OracleTextMatch({required this.name, this.printedName});

  final String name;
  final String? printedName;

  String get displayName =>
      printedName != null && printedName!.trim().isNotEmpty
          ? printedName!.trim()
          : name;
}

class OracleTextMatcher {
  OracleTextMatcher({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _headers = {
    'User-Agent': 'ManaPriceBR/0.1 (oracle text scanner lookup)',
    'Accept': 'application/json;q=0.9,*/*;q=0.8',
  };

  Future<OracleTextMatch?> findFromOcrText(String rawText) async {
    final fragments = _candidateFragments(rawText);
    for (final fragment in fragments) {
      final result = await _searchExactFragment(fragment);
      if (result != null) return result;
    }
    return null;
  }

  Future<OracleTextMatch?> _searchExactFragment(String fragment) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.scryfall.com/cards/search',
        queryParameters: {
          'q': 'oracle:"${_escape(fragment)}"',
          'unique': 'cards',
          'order': 'name',
          'include_multilingual': true,
        },
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final rows = response.data!['data'];
      if (rows is! List || rows.length != 1 || rows.first is! Map) return null;
      final row = Map<String, dynamic>.from(rows.first as Map);
      final name = row['name']?.toString().trim();
      if (name == null || name.isEmpty) return null;
      final printedName = row['printed_name']?.toString().trim();
      return OracleTextMatch(name: name, printedName: printedName);
    } catch (_) {
      return null;
    }
  }

  static List<String> _candidateFragments(String rawText) {
    final ignored = RegExp(
      r'^(magic|the gathering|wizards|legendary|creature|instant|sorcery|artifact|enchantment|planeswalker|land|basic land)$',
      caseSensitive: false,
    );
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line
            .replaceAll(RegExp(r'[^\p{L}\p{N}\x27,.:;!?()\- ]', unicode: true), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim())
        .where((line) => line.length >= 14 && !ignored.hasMatch(line))
        .where((line) => RegExp(r'[a-zA-Z]{4,}').hasMatch(line))
        .toList();

    lines.sort((a, b) => b.length.compareTo(a.length));

    final fragments = <String>[];
    for (final line in lines) {
      var candidate = line;
      if (candidate.length > 90) candidate = candidate.substring(0, 90).trim();
      if (candidate.length < 18) continue;
      if (!fragments.any((item) => item.toLowerCase() == candidate.toLowerCase())) {
        fragments.add(candidate);
      }
      if (fragments.length >= 4) break;
    }
    return fragments;
  }

  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
