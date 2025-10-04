import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class VehicleLocation {
  final String id;  // Unique identifier for the vehicle
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final DateTime timestamp;
  final bool isInRange;
  final bool alertShown;

  VehicleLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.timestamp,
    this.isInRange = false,
    this.alertShown = false,
  });

  VehicleLocation copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    DateTime? timestamp,
    bool? isInRange,
    bool? alertShown,
  }) {
    return VehicleLocation(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      timestamp: timestamp ?? this.timestamp,
      isInRange: isInRange ?? this.isInRange,
      alertShown: alertShown ?? this.alertShown,
    );
  }
}

class VehicleTrackingService {
  static const double MAX_VALID_DISTANCE = 20.0;  // Maximum distance to consider (meters)
  static const double MIN_VALID_DISTANCE = 2.0;   // Minimum distance to consider (meters)

  // Safety margins based on speed (in meters)
  static const double MARGIN_STATIONARY = 2.0;  // < 1 m/s
  static const double MARGIN_LOW_SPEED = 3.0;   // 1-5 m/s
  static const double MARGIN_HIGH_SPEED = 5.0;  // > 5 m/s

  final StreamController<List<VehicleLocation>> _nearbyVehiclesController = 
      StreamController<List<VehicleLocation>>.broadcast();
  final StreamController<bool> _isTrackingController = StreamController<bool>.broadcast();
  
  final Map<String, VehicleLocation> _trackedVehicles = {};
  String _selectedVehicleType = VehicleConfig.defaultType;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _cleanupTimer;
  bool _isTracking = false;

  Stream<List<VehicleLocation>> get nearbyVehicles => _nearbyVehiclesController.stream;
  Stream<bool> get isTracking => _isTrackingController.stream;

  // Initialize vehicle tracking
  Future<void> startTracking(BuildContext context) async {
    if (_isTracking) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      _isTracking = true;
      _isTrackingController.add(true);

      // Start position tracking with high accuracy
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen(_handlePositionUpdate);

      // Start cleanup timer for old vehicle locations
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _cleanOldLocations();
      });

      // Mock nearby vehicles for testing (remove in production)
      _startMockVehicles();

    } catch (e) {
      _isTracking = false;
      _isTrackingController.add(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting vehicle tracking: $e')),
        );
      }
    }
  }

  void _handlePositionUpdate(Position position) {
    _currentPosition = position;
    _updateNearbyVehicles();
  }

  void _updateNearbyVehicles() {
    if (_currentPosition == null) return;

    final now = DateTime.now();
    List<VehicleLocation> nearbyVehicles = [];

    for (var vehicle in _trackedVehicles.values) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        vehicle.latitude,
        vehicle.longitude
      );

      bool isInRange = _isInProximityRange(distance, _currentPosition!.speed);

      if (isInRange) {
        nearbyVehicles.add(vehicle.copyWith(
          isInRange: true,
          timestamp: now
        ));
      }
    }

    _nearbyVehiclesController.add(nearbyVehicles);
  }

  bool _isInProximityRange(double distance, double speed) {
    // Skip if distance is outside valid range
    if (distance < MIN_VALID_DISTANCE || distance > MAX_VALID_DISTANCE) {
      return false;
    }

    double safetyMargin = _getSpeedBasedSafetyMargin(speed);
    double alertThreshold = VehicleConfig.getWidth(_selectedVehicleType) + safetyMargin;
    return distance <= alertThreshold;
  }

  double _getSpeedBasedSafetyMargin(double speed) {
    if (speed < 1) {
      return MARGIN_STATIONARY;
    } else if (speed < 5) {
      return MARGIN_LOW_SPEED;
    }
    return MARGIN_HIGH_SPEED;
  }

  void _cleanOldLocations() {
    final now = DateTime.now();
    _trackedVehicles.removeWhere((_, vehicle) =>
      now.difference(vehicle.timestamp).inSeconds > 10);
  }

  // For testing - simulates nearby vehicles
  void _startMockVehicles() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTracking || _currentPosition == null) {
        timer.cancel();
        return;
      }

      // Simulate 2-3 vehicles moving nearby
      for (int i = 1; i <= 3; i++) {
        double offset = (i * 0.0001) * sin(DateTime.now().millisecondsSinceEpoch / 1000);
        
        _trackedVehicles['mock_vehicle_$i'] = VehicleLocation(
          id: 'mock_vehicle_$i',
          latitude: _currentPosition!.latitude + offset,
          longitude: _currentPosition!.longitude + offset,
          speed: _currentPosition!.speed + (Random().nextDouble() * 2 - 1),
          bearing: _currentPosition!.heading + offset * 100,
          timestamp: DateTime.now(),
        );
      }

      _updateNearbyVehicles();
    });
  }

  void setVehicleType(String type) {
    if (VehicleConfig.vehicleWidths.containsKey(type)) {
      _selectedVehicleType = type;
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _cleanupTimer?.cancel();
    _trackedVehicles.clear();
    _isTracking = false;
    _isTrackingController.add(false);
  }

  void dispose() {
    stopTracking();
    _nearbyVehiclesController.close();
    _isTrackingController.close();
  }
}

// Keep the same vehicle configuration
class VehicleConfig {
  static const Map<String, double> vehicleWidths = {
    'Compact SUV': 1.8,
    'Mid-size SUV': 2.0,
    'Full-size SUV': 2.2,
  };

  static const String defaultType = 'Mid-size SUV';
  static double getWidth(String type) => vehicleWidths[type] ?? vehicleWidths[defaultType]!;
}