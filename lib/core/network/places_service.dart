import 'package:dio/dio.dart';

import '../utils/env.dart';
import 'google_endpoints.dart';
import '../../features/search/data/models/place_suggestion_model.dart';

class PlacesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: GoogleEndpoints.placesBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final Dio _geoDio = Dio(
    BaseOptions(
      baseUrl: GoogleEndpoints.mapsApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<PlaceSuggestionModel>> autocomplete({
    required String input,
    String? countryCode,
  }) async {
    final apiKey = Env.googlePlacesApiKey;
    if (apiKey.isEmpty) {
      return [];
    }
    final response = await _dio.get(
      '/autocomplete/json',
      queryParameters: {
        'input': input,
        'key': apiKey,
        if (countryCode != null && countryCode.isNotEmpty)
          'components': 'country:$countryCode',
      },
    );

    final status = response.data['status'];
    if (status != 'OK') {
      return [];
    }

    final List<dynamic> predictions = response.data['predictions'] ?? [];
    return predictions
        .map((p) => PlaceSuggestionModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<String> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final apiKey = Env.googleGeocodingApiKey;
    if (apiKey.isEmpty) {
      return '';
    }
    final response = await _geoDio.get(
      '/geocode/json',
      queryParameters: {'latlng': '$lat,$lng', 'key': apiKey},
    );
    final status = response.data['status'];
    if (status != 'OK') {
      return '';
    }
    final results = response.data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      return '';
    }
    return results.first['formatted_address'] ?? '';
  }

  Future<Map<String, double>> placeDetails({required String placeId}) async {
    final apiKey = Env.googlePlacesApiKey;
    if (apiKey.isEmpty) {
      return {};
    }
    final response = await _dio.get(
      '/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry',
        'key': apiKey,
      },
    );
    final status = response.data['status'];
    if (status != 'OK') {
      return {};
    }
    final location = response.data['result']?['geometry']?['location'];
    if (location == null) return {};
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat is num && lng is num) {
      return {'lat': lat.toDouble(), 'lng': lng.toDouble()};
    }
    return {};
  }
}
