import 'package:google_maps_flutter/google_maps_flutter.dart';

class BangaloreLocation {
  final String name;
  final LatLng coordinates;
  final String description;

  BangaloreLocation({
    required this.name,
    required this.coordinates,
    required this.description,
  });
}

class BangaloreLocationsService {
  static final List<BangaloreLocation> locations = [
    // Central Bangalore
    BangaloreLocation(
      name: 'Bangalore City Center',
      coordinates: LatLng(12.9716, 77.5946),
      description: 'Vidhana Soudha - Government Center',
    ),
    BangaloreLocation(
      name: 'Vidhana Soudha',
      coordinates: LatLng(12.9844, 77.5907),
      description: 'Government Building, Cubbon Park',
    ),
    BangaloreLocation(
      name: 'Cubbon Park',
      coordinates: LatLng(12.9856, 77.5955),
      description: 'Public Park & Garden',
    ),
    BangaloreLocation(
      name: 'Lal Bagh Garden',
      coordinates: LatLng(12.9352, 77.5845),
      description: 'Botanical Garden, South Bangalore',
    ),
    
    // IT & Tech Hubs
    BangaloreLocation(
      name: 'Whitefield',
      coordinates: LatLng(12.9698, 77.7499),
      description: 'Major IT Hub',
    ),
    BangaloreLocation(
      name: 'Indiranagar IT Park',
      coordinates: LatLng(12.9716, 77.6412),
      description: 'IT Park, East Bangalore',
    ),
    BangaloreLocation(
      name: 'Electronic City',
      coordinates: LatLng(12.8471, 77.6771),
      description: 'Tech Park, South Bangalore',
    ),
    BangaloreLocation(
      name: 'Outer Ring Road Tech Park',
      coordinates: LatLng(12.9698, 77.7499),
      description: 'Major Tech Hub',
    ),
    
    // Shopping & Commercial
    BangaloreLocation(
      name: 'MG Road',
      coordinates: LatLng(12.9789, 77.6064),
      description: 'Shopping & Business District',
    ),
    BangaloreLocation(
      name: 'Brigade Road',
      coordinates: LatLng(12.9749, 77.6006),
      description: 'Shopping & Entertainment',
    ),
    BangaloreLocation(
      name: 'Commercial Street',
      coordinates: LatLng(12.9789, 77.5952),
      description: 'Shopping Mall Area',
    ),
    BangaloreLocation(
      name: 'Koramangala',
      coordinates: LatLng(12.9352, 77.6245),
      description: 'Startup Hub & Shopping',
    ),
    BangaloreLocation(
      name: 'Indiranagar 100 Feet Road',
      coordinates: LatLng(12.9716, 77.6412),
      description: 'Shopping & Dining',
    ),
    
    // Landmarks & Attractions
    BangaloreLocation(
      name: 'Bangalore Palace',
      coordinates: LatLng(12.9987, 77.5946),
      description: 'Historic Palace',
    ),
    BangaloreLocation(
      name: 'Tipu Sultan Palace',
      coordinates: LatLng(12.9685, 77.5917),
      description: 'Historical Monument',
    ),
    BangaloreLocation(
      name: 'ISKCON Temple',
      coordinates: LatLng(12.9716, 77.6412),
      description: 'Religious Temple',
    ),
    BangaloreLocation(
      name: 'Ulsoor Lake',
      coordinates: LatLng(12.9799, 77.6102),
      description: 'Lake & Recreation Area',
    ),
    
    // Malls & Entertainment
    BangaloreLocation(
      name: 'Forum Mall Koramangala',
      coordinates: LatLng(12.9352, 77.6245),
      description: 'Shopping Mall',
    ),
    BangaloreLocation(
      name: 'Orion Mall Whitefield',
      coordinates: LatLng(12.9698, 77.7499),
      description: 'Shopping Mall',
    ),
    BangaloreLocation(
      name: 'Phoenix Market City',
      coordinates: LatLng(12.9352, 77.6245),
      description: 'Shopping & Entertainment',
    ),
    BangaloreLocation(
      name: 'UB City Mall',
      coordinates: LatLng(12.9749, 77.6006),
      description: 'Premium Shopping Center',
    ),
    
    // Transport Hubs
    BangaloreLocation(
      name: 'Bangalore City Railway Station',
      coordinates: LatLng(12.9789, 77.5931),
      description: 'Main Railway Station',
    ),
    BangaloreLocation(
      name: 'Kempegowda International Airport',
      coordinates: LatLng(13.1939, 77.7064),
      description: 'International Airport',
    ),
    BangaloreLocation(
      name: 'Majestic Bus Station',
      coordinates: LatLng(12.9765, 77.5738),
      description: 'Central Bus Station',
    ),
    
    // Hospitals & Medical
    BangaloreLocation(
      name: 'Apollo Hospital Bangalore',
      coordinates: LatLng(12.9749, 77.6006),
      description: 'Multi-specialty Hospital',
    ),
    BangaloreLocation(
      name: 'St Johns Hospital',
      coordinates: LatLng(12.9749, 77.6006),
      description: 'Medical Center',
    ),
    BangaloreLocation(
      name: 'Fortis Hospital',
      coordinates: LatLng(12.9698, 77.7499),
      description: 'Healthcare Center',
    ),
    
    // Educational Institutions
    BangaloreLocation(
      name: 'Indian Institute of Science (IISc)',
      coordinates: LatLng(12.9789, 77.5859),
      description: 'Premier Research Institute',
    ),
    BangaloreLocation(
      name: 'Bangalore University',
      coordinates: LatLng(12.9789, 77.5859),
      description: 'University Campus',
    ),
    
    // Highways & Major Junctions
    BangaloreLocation(
      name: 'Silk Board Junction',
      coordinates: LatLng(12.9352, 77.6297),
      description: 'Major Traffic Junction',
    ),
    BangaloreLocation(
      name: 'Hebbal Junction',
      coordinates: LatLng(13.0012, 77.5897),
      description: 'North Bangalore Junction',
    ),
    BangaloreLocation(
      name: 'Outer Ring Road',
      coordinates: LatLng(13.0500, 77.6500),
      description: 'Ring Road Highway',
    ),
    BangaloreLocation(
      name: 'Bangalore-Mysore Road',
      coordinates: LatLng(12.7333, 77.3667),
      description: 'Major Highway South',
    ),
  ];

  static List<BangaloreLocation> searchLocations(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return locations
        .where((loc) =>
            loc.name.toLowerCase().contains(lowerQuery) ||
            loc.description.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
