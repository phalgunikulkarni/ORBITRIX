import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  final String apiKey;

  GooglePlacesService(this.apiKey);

  /// Autocomplete suggestions with optional location bias (lat,lng) and radius in meters
  Future<List<AutocompletePrediction>> autocomplete(String input,
      {double? lat, double? lng, int? radius, String? country}) async {
    if (input.isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': apiKey,
      'types': 'geocode', // bias to geocoding results (addresses/places)
      'language': 'en'
    };

    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      if (radius != null) params['radius'] = radius.toString();
    }

    if (country != null) {
      params['components'] = 'country:$country';
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', params);

    print('Making Places API call to: $uri');
    final resp = await http.get(uri);
    print('Places API response status: ${resp.statusCode}');
    
    if (resp.statusCode != 200) {
      print('Places API error response: ${resp.body}');
      throw Exception('Places autocomplete failed: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);
    print('Places API response: ${data['status']} - ${data['predictions']?.length ?? 0} results');
    
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      print('Places API error details: ${data['error_message'] ?? 'No error message'}');
      throw Exception('Places API error: ${data['status']}');
    }

    final List<dynamic> preds = data['predictions'] as List<dynamic>? ?? [];
    return preds.map((p) => AutocompletePrediction.fromJson(p)).toList();
  }

  /// Get place details (including geometry/location) by place_id
  Future<PlaceDetail?> getPlaceDetail(String placeId) async {
    final params = {
      'place_id': placeId,
      'key': apiKey,
      'fields': 'geometry,name,formatted_address'
    };

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', params);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Place details failed: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);
    if (data['status'] != 'OK') return null;
    final result = data['result'] as Map<String, dynamic>;
    return PlaceDetail.fromJson(result);
  }
}

class AutocompletePrediction {
  final String placeId;
  final String description;

  AutocompletePrediction({required this.placeId, required this.description});

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return AutocompletePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}

class PlaceDetail {
  final String name;
  final String address;
  final double lat;
  final double lng;

  PlaceDetail({required this.name, required this.address, required this.lat, required this.lng});

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final loc = json['geometry']?['location'] ?? {};
    return PlaceDetail(
      name: json['name'] as String? ?? '',
      address: json['formatted_address'] as String? ?? '',
      lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
