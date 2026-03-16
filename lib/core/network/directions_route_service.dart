import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:goapp/core/maps/map_types.dart';
import 'package:goapp/core/network/google_endpoints.dart';

class DirectionsRouteService {
  DirectionsRouteService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<LatLng>?> fetchDrivingRoute({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    bool preferDetailedSteps = true,
  }) async {
    final String resolvedApiKey = apiKey;

    if (resolvedApiKey.isNotEmpty) {
      final List<LatLng>? legacyRoute = await _fetchLegacyDirectionsRoute(
        origin: origin,
        destination: destination,
        apiKey: resolvedApiKey,
        preferDetailedSteps: preferDetailedSteps,
      );
      if (_isUsableRoute(legacyRoute)) return legacyRoute;

      final List<LatLng>? routesApiRoute = await _fetchRoutesApiRoute(
        origin: origin,
        destination: destination,
        apiKey: resolvedApiKey,
        preferDetailedSteps: preferDetailedSteps,
      );
      if (_isUsableRoute(routesApiRoute)) return routesApiRoute;
    }

    final List<LatLng>? osrmRoute = await _fetchOsrmRoute(
      origin: origin,
      destination: destination,
    );
    if (_isUsableRoute(osrmRoute)) return osrmRoute;

    return null;
  }

  bool _isUsableRoute(List<LatLng>? route) {
    return route != null && route.length >= 3;
  }

  Future<List<LatLng>?> _fetchLegacyDirectionsRoute({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    required bool preferDetailedSteps,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '${GoogleEndpoints.mapsBaseUrl}${GoogleEndpoints.directionsJson}',
        queryParameters: <String, dynamic>{
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': apiKey,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      if (data['status'] != 'OK') return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final firstRoute = routes.first;
      if (firstRoute is! Map<String, dynamic>) return null;

      if (preferDetailedSteps) {
        final List<LatLng> stepPoints = decodeStepsPolyline(firstRoute);
        if (stepPoints.length > 1) {
          return dedupeSequential(stepPoints);
        }
      }

      final overview = firstRoute['overview_polyline'];
      if (overview is! Map<String, dynamic>) return null;
      final points = overview['points'];
      if (points is! String || points.isEmpty) return null;
      return decodePolyline(points);
    } catch (_) {
      return null;
    }
  }

  Future<List<LatLng>?> _fetchRoutesApiRoute({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    required bool preferDetailedSteps,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '${GoogleEndpoints.routesBaseUrl}${GoogleEndpoints.routesCompute}',
        data: <String, dynamic>{
          'origin': <String, dynamic>{
            'location': <String, dynamic>{
              'latLng': <String, double>{
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },
          'destination': <String, dynamic>{
            'location': <String, dynamic>{
              'latLng': <String, double>{
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_UNAWARE',
          'computeAlternativeRoutes': false,
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'GEO_JSON_LINESTRING',
        },
        options: Options(
          headers: <String, String>{
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'routes.polyline.geoJsonLinestring,'
                'routes.polyline.encodedPolyline',
          },
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final firstRouteRaw = routes.first;
      if (firstRouteRaw is! Map) return null;
      final Map<String, dynamic> firstRoute = Map<String, dynamic>.from(
        firstRouteRaw,
      );

      final polyline = firstRoute['polyline'];
      if (polyline is! Map) return null;
      final geoJsonLineString = polyline['geoJsonLinestring'];
      if (geoJsonLineString is String && geoJsonLineString.isNotEmpty) {
        final List<LatLng> geoJsonPoints = _decodeGeoJsonLineString(
          geoJsonLineString,
        );
        if (geoJsonPoints.length >= 3) {
          return dedupeSequential(geoJsonPoints);
        }
      }
      final encoded = polyline['encodedPolyline'];
      if (encoded is! String || encoded.isEmpty) return null;
      return decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodeGeoJsonLineString(String geoJson) {
    try {
      final dynamic parsed = jsonDecode(geoJson);
      if (parsed is! Map) return const <LatLng>[];
      final type = parsed['type'];
      if (type != 'LineString') return const <LatLng>[];
      final dynamic coordsRaw = parsed['coordinates'];
      if (coordsRaw is! List) return const <LatLng>[];
      final List<LatLng> points = <LatLng>[];
      for (final dynamic pair in coordsRaw) {
        if (pair is! List || pair.length < 2) continue;
        final dynamic lngRaw = pair[0];
        final dynamic latRaw = pair[1];
        if (lngRaw is! num || latRaw is! num) continue;
        points.add(LatLng(latRaw.toDouble(), lngRaw.toDouble()));
      }
      return points;
    } catch (_) {
      return const <LatLng>[];
    }
  }

  Future<List<LatLng>?> _fetchOsrmRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final String path =
          'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}';
      final Response<dynamic> response = await _dio.get(
        path,
        queryParameters: <String, dynamic>{
          'overview': 'full',
          'geometries': 'polyline',
          'alternatives': 'false',
          'steps': 'false',
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      if (data['code'] != 'Ok') return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final firstRoute = routes.first;
      if (firstRoute is! Map<String, dynamic>) return null;
      final geometry = firstRoute['geometry'];
      if (geometry is! String || geometry.isEmpty) return null;
      return decodePolyline(geometry);
    } catch (_) {
      return null;
    }
  }

  List<LatLng> decodeStepsPolyline(Map<String, dynamic> route) {
    final List<LatLng> path = <LatLng>[];
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return path;

    for (final leg in legs) {
      if (leg is! Map<String, dynamic>) continue;
      final steps = leg['steps'];
      if (steps is! List) continue;
      for (final step in steps) {
        if (step is! Map<String, dynamic>) continue;
        final polyline = step['polyline'];
        if (polyline is! Map<String, dynamic>) continue;
        final points = polyline['points'];
        if (points is! String || points.isEmpty) continue;
        path.addAll(decodePolyline(points));
      }
    }
    return path;
  }

  List<LatLng> dedupeSequential(List<LatLng> points) {
    if (points.isEmpty) return points;
    final List<LatLng> out = <LatLng>[points.first];
    for (int i = 1; i < points.length; i++) {
      final prev = out.last;
      final cur = points[i];
      if (prev.latitude == cur.latitude && prev.longitude == cur.longitude) {
        continue;
      }
      out.add(cur);
    }
    return out;
  }

  List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        if (index >= encoded.length) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        if (index >= encoded.length) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
