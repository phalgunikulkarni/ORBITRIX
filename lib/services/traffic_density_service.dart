import 'dart:async';
import 'package:flutter/material.dart';

/// Traffic density levels
enum DensityLevel { low, moderate, high }

/// Service class for handling traffic density calculations and predictions in Bangalore
class TrafficDensityService {
  // Bangalore city boundary coordinates (expanded to cover greater Bangalore)
  static const double blrNorthLat = 13.173577; // Extended north
  static const double blrSouthLat = 12.823210; // Extended south
  static const double blrEastLong = 77.842256; // Extended east
  static const double blrWestLong = 77.338899; // Extended west
  /// Singleton instance
  static final TrafficDensityService _instance = TrafficDensityService._internal();
  factory TrafficDensityService() => _instance;
  TrafficDensityService._internal();

  /// Current traffic density level
  DensityLevel _currentDensityLevel = DensityLevel.low;

  /// Stream controller for traffic density updates
  final _densityController = StreamController<DensityLevel>.broadcast();

  /// Stream of traffic density updates
  Stream<DensityLevel> get densityStream => _densityController.stream;

  /// Check if location is within Bangalore city limits
  bool isWithinBangalore(double latitude, double longitude) {
    return latitude >= blrSouthLat && 
           latitude <= blrNorthLat && 
           longitude >= blrWestLong && 
           longitude <= blrEastLong;
  }

  /// Calculate traffic density based on vehicle count and area
  DensityLevel calculateDensity(int vehicleCount, double area, double latitude, double longitude) {
    // First check if the location is within Bangalore
    if (!isWithinBangalore(latitude, longitude)) {
      throw Exception('Location outside Bangalore city limits');
    }

    // Calculate density percentage (vehicles per unit area)
    double density = (vehicleCount / area) * 100;

    // Bangalore-specific density thresholds (adjusted for city traffic patterns)
    if (density < 15) { // Higher threshold for Bangalore's typical traffic
      return DensityLevel.low;
    } else if (density < 30) {
      return DensityLevel.moderate;
    } else {
      return DensityLevel.high;
    }
  }

  /// Update traffic density information
  void updateDensity(DensityLevel newLevel) {
    _currentDensityLevel = newLevel;
    _densityController.add(newLevel);
  }

  /// Get safety recommendations based on current traffic density and Bangalore-specific conditions
  String getSafetyRecommendations() {
    switch (_currentDensityLevel) {
      case DensityLevel.low:
        return "Normal Bangalore traffic. Stay in your lane and maintain safe distance.";
      case DensityLevel.moderate:
        return "Moderate Bangalore traffic. Watch for two-wheelers and maintain extra distance.";
      case DensityLevel.high:
        return "Heavy Bangalore traffic! Use alternate routes if possible. Exercise extreme caution.";
      default:
        return "Stay alert and follow traffic rules.";
    }
  }

  /// Get color indication for current density level
  Color getDensityColor() {
    switch (_currentDensityLevel) {
      case DensityLevel.low:
        return Colors.green;
      case DensityLevel.moderate:
        return Colors.orange;
      case DensityLevel.high:
        return Colors.red;
    }
  }

  /// Dispose of resources
  void dispose() {
    _densityController.close();
  }
}