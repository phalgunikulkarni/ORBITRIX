import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/traffic_density_service.dart';

class RouteSegment {
  final LatLng start;
  final LatLng end;
  final DensityLevel trafficDensity;

  const RouteSegment(this.start, this.end, this.trafficDensity);

  Color get color {
    switch (trafficDensity) {
      case DensityLevel.low:
        return Colors.green;
      case DensityLevel.moderate:
        return Colors.orange;
      case DensityLevel.high:
        return Colors.red;
    }
    return Colors.blue;  // Default color for unknown density
  }
}