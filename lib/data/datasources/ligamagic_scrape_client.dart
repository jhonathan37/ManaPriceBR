import 'package:dio/dio.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicScrapeClient {
  LigaMagicScrapeClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    final uri = LigaMagicUrlBuilder.build(request);
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      ),
    );

    final body = response.data;
    if (body == null || body.isEmpty) return null;

    return LigaMagicScrapeParser.parse(
      cardName: request.cardName,
      html: body,
    );
  }
}
