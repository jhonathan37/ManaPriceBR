import 'package:dio/dio.dart';

class ScryfallCatalogCard {
  const ScryfallCatalogCard({
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
}

class ScryfallCatalogClient {
  ScryfallCatalogClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<ScryfallCatalogCard?> find(String query) async {
    final name = query.trim();
    if (name.isEmpty) return null;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.scryfall.com/cards/named',
      queryParameters: {'fuzzy': name},
      options: Options(
        headers: const {
          'User-Agent': 'ManaPriceBR/0.1 (card catalog lookup)',
          'Accept': 'application/json;q=0.9,*/*;q=0.8',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) return null;
    final data = response.data!;
    final canonicalName = data['name'] as String?;
    if (canonicalName == null || canonicalName.trim().isEmpty) return null;

    String? imageUrl;
    final imageUris = data['image_uris'];
    if (imageUris is Map) {
      imageUrl = imageUris['normal'] as String? ?? imageUris['small'] as String?;
    }

    if (imageUrl == null) {
      final faces = data['card_faces'];
      if (faces is List && faces.isNotEmpty && faces.first is Map) {
        final firstFace = faces.first as Map;
        final faceImages = firstFace['image_uris'];
        if (faceImages is Map) {
          imageUrl = faceImages['normal'] as String? ?? faceImages['small'] as String?;
        }
      }
    }

    return ScryfallCatalogCard(name: canonicalName, imageUrl: imageUrl);
  }
}
