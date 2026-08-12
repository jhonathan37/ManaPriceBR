import 'package:dio/dio.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicScrapeClient {
  LigaMagicScrapeClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    final direct = await _fetchAndParse(
      request,
      LigaMagicUrlBuilder.card(request),
    );
    if (direct != null) return direct;

    return _fetchAndParse(
      request,
      LigaMagicUrlBuilder.search(request),
    );
  }

  Future<LigaMagicScrapeResult?> _fetchAndParse(
    PriceLookupRequest request,
    Uri uri,
  ) async {
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/131.0 Mobile Safari/537.36',
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) return null;
    final body = response.data;
    if (body == null || body.isEmpty) return null;

    return LigaMagicScrapeParser.parse(
      request: request,
      html: body,
    );
  }
}
