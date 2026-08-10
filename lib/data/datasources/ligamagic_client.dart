import 'package:dio/dio.dart';

import 'ligamagic_url_builder.dart';
import 'price_source.dart';

/// HTTP client boundary for LigaMagic.
///
/// This intentionally does not pretend that LigaMagic exposes a public JSON
/// API. The response parser will be added only after the actual response shape
/// has been verified. Until then, callers receive null instead of fabricated
/// prices.
class LigaMagicClient implements PriceSource {
  LigaMagicClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<PriceLookupResponse?> lookup(PriceLookupRequest request) async {
    final uri = LigaMagicUrlBuilder.build(request);

    try {
      final response = await _dio.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          maxRedirects: 5,
          headers: const {
            'Accept': 'text/html,application/xhtml+xml',
            'User-Agent': 'ManaPriceBR/0.1',
          },
        ),
      );

      // The site response must be inspected and mapped before a price can be
      // trusted. Do not parse arbitrary numbers from the page as card prices.
      if (response.statusCode != 200 || response.data == null) return null;
      return null;
    } on DioException {
      return null;
    }
  }
}
