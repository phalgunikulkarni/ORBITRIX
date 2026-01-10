import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';

/// Service to detect if vehicle is moving and if it's inside a building
/// Returns false when vehicle should NOT detect other vehicles
class MovementDetectionService {
  static const double SPEED_THRESHOLD_KMPH = 5.0; // Below this speed = stopped (changed from 2.0 to 3.0)
  static const double ACCURACY_THRESHOLD_METERS = 15.0; // GPS accuracy > 15m suggests indoor
  static const int SPEED_CHECK_INTERVAL_SECONDS = 3;
  
  final Location _location = Location();
  StreamSubscription? _locationSubscription;
  
  double _lastLatitude = 0;
  double _lastLongitude = 0;
  int _lastTimestamp = 0;
  bool _isMoving = false;
  bool _isIndoor = false;

  /// Stream of movement status (true = moving/outdoor, false = stopped/indoor)
  late Stream<bool> movementStatusStream;

  MovementDetectionService() {
    movementStatusStream = Stream.periodic(
      const Duration(seconds: SPEED_CHECK_INTERVAL_SECONDS),
      (_) => _isMoving && !_isIndoor,
    );
  }

  /// Start monitoring movement
  Future<void> startMonitoring() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) return;

      // Subscribe to location changes
      _locationSubscription = _location.onLocationChanged.listen(
        (LocationData currentLocation) {
          _updateMovementStatus(currentLocation);
        },
        onError: (error) {
          print('Location monitoring error: $error');
        },
      );
    } catch (e) {
      print('Error starting movement monitoring: $e');
    }
  }

  /// Stop monitoring movement
  void stopMonitoring() {
    _locationSubscription?.cancel();
  }

  /// Update movement status based on location data
  void _updateMovementStatus(LocationData currentLocation) {
    final lat = currentLocation.latitude;
    final lon = currentLocation.longitude;
    final accuracy = currentLocation.accuracy;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (lat == null || lon == null) return;

    // Check if device is indoors (poor GPS accuracy)
    _isIndoor = accuracy != null && accuracy > ACCURACY_THRESHOLD_METERS;

    // Calculate speed if we have previous location
    if (_lastLatitude != 0 && _lastLongitude != 0 && _lastTimestamp != 0) {
      final timeDeltaSeconds = (timestamp - _lastTimestamp) / 1000.0;
      if (timeDeltaSeconds > 0) {
        final distance = _calculateDistance(_lastLatitude, _lastLongitude, lat, lon);
        final speedMps = distance / timeDeltaSeconds;
        final speedKmph = speedMps * 3.6; // Convert m/s to km/h

        _isMoving = speedKmph >= SPEED_THRESHOLD_KMPH;

        print('Speed: ${speedKmph.toStringAsFixed(2)} km/h, GPS Accuracy: ${accuracy?.toStringAsFixed(1)}m, Moving: $_isMoving, Indoor: $_isIndoor');
      }
    }

    _lastLatitude = lat;
    _lastLongitude = lon;
    _lastTimestamp = timestamp;
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180.0);

  /// Check if vehicle detection should be active
  /// Returns true if vehicle is moving AND outdoors
  bool shouldDetectVehicles() {
    return _isMoving && !_isIndoor;
  }

  /// Get current movement status
  bool get isMoving => _isMoving;
  bool get isIndoor => _isIndoor;
}
