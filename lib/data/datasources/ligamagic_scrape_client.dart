import 'package:dio/dio.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicScrapeClient {
  LigaMagicScrapeClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    if (!request.hasExactPrinting) return null;

    final uri = LigaMagicUrlBuilder.build(request);
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'pt-BR,pt;q=0.9',
          'User-Agent': 'Mozilla/5.0 ManaPriceBR/0.1',
        },
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
