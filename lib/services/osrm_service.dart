import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OSRMService {
  // OSRM public API endpoint - completely free, no API key needed
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Get route from origin to destination using OSRM
  /// Returns a list of LatLng coordinates representing the route
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    try {
      // OSRM expects coordinates as longitude,latitude (not latitude,longitude)
      final String url = '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

      print('OSRM URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('OSRM request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check if route was found
        if (json['code'] != 'Ok') {
          print('OSRM Error: ${json['code']} - ${json['message']}');
          return [];
        }

        // Extract coordinates from the first route
        if (json['routes'].isEmpty) {
          print('OSRM: No routes found');
          return [];
        }

        final route = json['routes'][0];
        final geometry = route['geometry'];
        final coordinates = geometry['coordinates'] as List;

        // Convert GeoJSON coordinates (lon,lat) to LatLng (lat,lon)
        final routePoints = coordinates
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();

        print('OSRM: Route calculated with ${routePoints.length} points');
        print('OSRM: Distance: ${route['distance']}m, Duration: ${route['duration']}s');
        
        return routePoints;
      } else {
        print('OSRM Error: HTTP ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('OSRM Error: $e');
      return [];
    }
  }

  /// Get route details (distance, duration) without full geometry
  static Future<Map<String, dynamic>?> getRouteDetails(
      LatLng origin, LatLng destination) async {
    try {
      final String url = '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=false';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('OSRM request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] != 'Ok' || json['routes'].isEmpty) {
          return null;
        }

        final route = json['routes'][0];
        return {
          'distance': route['distance'], // meters
          'duration': route['duration'], // seconds
          'distance_km': (route['distance'] as num) / 1000,
          'duration_min': ((route['duration'] as num) / 60).toStringAsFixed(1),
        };
      }
      return null;
    } catch (e) {
      print('OSRM Details Error: $e');
      return null;
    }
  }
}
