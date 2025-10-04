class Place {
  final String osmId;
  final String name;
  final String? street;
  final String? houseNumber;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final double latitude;
  final double longitude;
  final String type;
  final double? importance;

  Place({
    required this.osmId,
    required this.name,
    this.street,
    this.houseNumber,
    this.city,
    this.state,
    this.country,
    this.postcode,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.importance,
  });

  String get displayAddress {
    final components = <String>[];
    
    if (street != null) {
      if (houseNumber != null) {
        components.add('$street $houseNumber');
      } else {
        components.add(street!);
      }
    }
    
    if (city != null) components.add(city!);
    if (state != null) components.add(state!);
    if (country != null) components.add(country!);
    
    return components.join(', ');
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return Place(
      osmId: properties['osm_id']?.toString() ?? '',
      name: properties['name'] ?? '',
      street: properties['street'],
      houseNumber: properties['housenumber'],
      city: properties['city'],
      state: properties['state'],
      country: properties['country'],
      postcode: properties['postcode'],
      latitude: coordinates[1].toDouble(),
      longitude: coordinates[0].toDouble(),
      type: properties['type'] ?? 'unknown',
      importance: properties['importance']?.toDouble(),
    );
  }
}