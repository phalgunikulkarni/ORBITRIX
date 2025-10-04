import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

class PhotonPlaceSearchService {
  static const String _baseUrl = 'https://photon.komoot.io';
  static const int _limit = 5; // Number of suggestions to return

  final StreamController<List<Place>> _suggestionsController = 
      StreamController<List<Place>>.broadcast();
  Timer? _debounceTimer;

  Stream<List<Place>> get suggestions => _suggestionsController.stream;

  Future<List<Place>> searchPlaces(String query, {double? lat, double? lon}) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Build query parameters
      final Map<String, String> params = {
        'q': query,
        'limit': _limit.toString(),
      };

      // Add location bias if available
      if (lat != null && lon != null) {
        params['lat'] = lat.toString();
        params['lon'] = lon.toString();
      }

      // Make API request
      final Uri uri = Uri.parse('$_baseUrl/api').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> features = data['features'] as List;
        
        return features
            .map((feature) => Place.fromJson(feature))
            .where((place) => place.name.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  void searchWithDebounce(String query, {double? lat, double? lon}) {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // Set new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        _suggestionsController.add([]);
        return;
      }

      final places = await searchPlaces(query, lat: lat, lon: lon);
      _suggestionsController.add(places);
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _suggestionsController.close();
  }
}