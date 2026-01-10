class VehicleInfo {
  final String category; // Cars, Trucks, Buses, etc.
  final String vehicleType; // Sedan, Hatchback, etc.
  final String? suvCategory; // For SUVs: Compact, Mid-Size, Full-Size

  VehicleInfo({
    required this.category,
    required this.vehicleType,
    this.suvCategory,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'vehicleType': vehicleType,
      'suvCategory': suvCategory,
    };
  }

  // Create from JSON
  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      category: json['category'] as String,
      vehicleType: json['vehicleType'] as String,
      suvCategory: json['suvCategory'] as String?,
    );
  }
}
