import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = 'AIzaSyCx8UgZDXtJ-w9RoIl2-QHn8FEl3wtch5o';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // Search for places/locations
  static Future<List<PlacePrediction>> searchPlaces(String input) async {
    if (input.isEmpty) return [];

    try {
      final String url =
          '$_baseUrl/place/autocomplete/json?input=$input&key=$_apiKey';

      print('[PlacesService] Searching for: $input');
      print('[PlacesService] URL: $url');

      final response = await http.get(Uri.parse(url));

      print('[PlacesService] Response status: ${response.statusCode}');
      print('[PlacesService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final predictions = json['predictions'] as List;

        print('[PlacesService] Found ${predictions.length} predictions');

        return predictions
            .map((p) => PlacePrediction(
                  placeId: p['place_id'],
                  description: p['description'],
                  mainText: p['structured_formatting']['main_text'] ?? '',
                ))
            .toList();
      }
      print('[PlacesService] Non-200 status code');
      return [];
    } catch (e) {
      print('[PlacesService] Error searching places: $e');
      return [];
    }
  }

  // Get lat/lng for a place ID
  static Future<LatLng?> getPlaceLatLng(String placeId) async {
    try {
      final String url =
          '$_baseUrl/place/details/json?place_id=$placeId&fields=geometry&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final geometry = json['result']['geometry']['location'];

        return LatLng(geometry['lat'], geometry['lng']);
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
  });
}
