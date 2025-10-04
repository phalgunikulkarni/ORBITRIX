class Place {
  final String placeId;
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final String? type;

  Place({
    required this.placeId,
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.type,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return Place(
      placeId: properties['osm_id']?.toString() ?? '',
      name: properties['name'] ?? '',
      displayName: properties['name'] ?? '',
      latitude: coordinates[1].toDouble(),
      longitude: coordinates[0].toDouble(),
      city: properties['city'],
      state: properties['state'],
      country: properties['country'],
      postcode: properties['postcode'],
      type: properties['type'],
    );
  }
}