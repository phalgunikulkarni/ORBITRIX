import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  static const String _apiKey = 'AIzaSyDSQtWo79Y5Kfv5lBTBfc1em40gWpazliQ';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route between two locations
  /// Returns list of LatLng points representing the route
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    try {
      final String url = 
          '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey';

      print('Requesting directions from Google Maps API...');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['status'] != 'OK') {
          print('Directions API error: ${json['status']}');
          print('Error message: ${json['error_message'] ?? "Unknown error"}');
          
          // Fallback: Return simple straight line route if API fails
          print('Using fallback route (direct line)...');
          return _generateSimpleFallbackRoute(origin, destination);
        }

        final routes = json['routes'] as List;
        if (routes.isEmpty) {
          print('No routes found');
          return _generateSimpleFallbackRoute(origin, destination);
        }

        final route = routes[0];
        final legs = route['legs'] as List;
        if (legs.isEmpty) {
          print('No legs in route');
          return _generateSimpleFallbackRoute(origin, destination);
        }

        final List<LatLng> points = [];
        
        // Parse all steps in all legs to get detailed route
        for (var leg in legs) {
          final steps = leg['steps'] as List;
          for (var step in steps) {
            final polyline = step['polyline']['points'] as String;
            final decodedPoints = _decodePolyline(polyline);
            points.addAll(decodedPoints);
          }
        }

        print('Route decoded successfully: ${points.length} points');
        return points;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return _generateSimpleFallbackRoute(origin, destination);
      }
    } catch (e) {
      print('Error getting directions: $e');
      return _generateSimpleFallbackRoute(origin, destination);
    }
  }

  /// Generate a simple fallback route (direct line with intermediate points)
  static List<LatLng> _generateSimpleFallbackRoute(LatLng origin, LatLng destination) {
    final List<LatLng> points = [origin];
    
    // Add intermediate points for a more realistic looking route
    final latDiff = destination.latitude - origin.latitude;
    final lngDiff = destination.longitude - origin.longitude;
    
    // Create 20 intermediate points
    for (int i = 1; i < 20; i++) {
      final fraction = i / 20;
      final lat = origin.latitude + (latDiff * fraction);
      final lng = origin.longitude + (lngDiff * fraction);
      points.add(LatLng(lat, lng));
    }
    
    points.add(destination);
    print('Generated fallback route with ${points.length} points');
    return points;
  }

  /// Decode polyline string to list of LatLng points
  /// Google Maps returns routes as encoded polylines
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;

      points.add(LatLng(latitude, longitude));
    }

    return points;
  }

  /// Get distance and duration for a route
  static Future<RouteInfo?> getRouteInfo(LatLng origin, LatLng destination) async {
    try {
      final String url = 
          '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['status'] != 'OK') {
          return null;
        }

        final routes = json['routes'] as List;
        if (routes.isEmpty) return null;

        final legs = routes[0]['legs'] as List;
        if (legs.isEmpty) return null;

        final leg = legs[0];
        
        return RouteInfo(
          distance: leg['distance']['text'],
          distanceValue: leg['distance']['value'],
          duration: leg['duration']['text'],
          durationValue: leg['duration']['value'],
          startAddress: leg['start_address'],
          endAddress: leg['end_address'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting route info: $e');
      return null;
    }
  }
}

/// Route information class
class RouteInfo {
  final String distance;
  final int distanceValue;
  final String duration;
  final int durationValue;
  final String startAddress;
  final String endAddress;

  RouteInfo({
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    required this.startAddress,
    required this.endAddress,
  });

  @override
  String toString() {
    return 'Distance: $distance, Duration: $duration';
  }
}
