import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

// Configuration for different vehicle types and their characteristics
class VehicleConfig {
  static const Map<String, VehicleSpecs> vehicleSpecs = {
    'Compact SUV': VehicleSpecs(width: 1.8, length: 4.2, brakingDistance: 15.0),
    'Mid-size SUV': VehicleSpecs(width: 2.0, length: 4.6, brakingDistance: 18.0),
    'Full-size SUV': VehicleSpecs(width: 2.2, length: 5.2, brakingDistance: 22.0),
    'Motorcycle': VehicleSpecs(width: 0.8, length: 2.2, brakingDistance: 8.0),
    'Car': VehicleSpecs(width: 1.8, length: 4.5, brakingDistance: 16.0),
  };

  static const String defaultType = 'Mid-size SUV';
  static VehicleSpecs getSpecs(String type) => vehicleSpecs[type] ?? vehicleSpecs[defaultType]!;
}

class VehicleSpecs {
  final double width;
  final double length;
  final double brakingDistance; // Average braking distance at 60 km/h
  
  const VehicleSpecs({
    required this.width,
    required this.length,
    required this.brakingDistance,
  });
}

// Enhanced collision risk levels
enum CollisionRisk {
  none,      // No risk
  low,       // Approaching but safe
  medium,    // Caution needed
  high,      // Immediate danger
  critical   // Collision imminent
}

class CollisionMetrics {
  final double timeToCollision; // Time in seconds until potential collision
  final double relativeSpeed;   // Relative approach speed (m/s)
  final double collisionProbability; // Probability of collision (0.0 - 1.0)
  final CollisionRisk riskLevel;
  final String riskDescription;

  CollisionMetrics({
    required this.timeToCollision,
    required this.relativeSpeed,
    required this.collisionProbability,
    required this.riskLevel,
    required this.riskDescription,
  });
}

class DetectedVehicle {
  final BluetoothDevice device;
  final int rssi;
  final double distance;
  final DateTime lastSeen;
  final List<double> distanceHistory;
  final List<DateTime> timeHistory;
  final double velocity; // Relative velocity (negative = approaching, positive = moving away)
  final double acceleration; // Rate of velocity change
  final CollisionMetrics? collisionMetrics;
  final bool alertTriggered;

  DetectedVehicle({
    required this.device,
    required this.rssi,
    required this.distance,
    required this.lastSeen,
    List<double>? distanceHistory,
    List<DateTime>? timeHistory,
    this.velocity = 0.0,
    this.acceleration = 0.0,
    this.collisionMetrics,
    this.alertTriggered = false,
  }) : this.distanceHistory = distanceHistory ?? [distance],
       this.timeHistory = timeHistory ?? [lastSeen];

  DetectedVehicle copyWith({
    BluetoothDevice? device,
    int? rssi,
    double? distance,
    DateTime? lastSeen,
    List<double>? distanceHistory,
    List<DateTime>? timeHistory,
    double? velocity,
    double? acceleration,
    CollisionMetrics? collisionMetrics,
    bool? alertTriggered,
  }) {
    return DetectedVehicle(
      device: device ?? this.device,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      lastSeen: lastSeen ?? this.lastSeen,
      distanceHistory: distanceHistory ?? this.distanceHistory,
      timeHistory: timeHistory ?? this.timeHistory,
      velocity: velocity ?? this.velocity,
      acceleration: acceleration ?? this.acceleration,
      collisionMetrics: collisionMetrics ?? this.collisionMetrics,
      alertTriggered: alertTriggered ?? this.alertTriggered,
    );
  }

  bool get isApproaching => velocity < -0.5; // Approaching at > 0.5 m/s
  bool get isMovingAway => velocity > 0.5;   // Moving away at > 0.5 m/s
  bool get isStationary => velocity.abs() <= 0.5; // Essentially stationary
}

class SmartCollisionDetectionService {
  static const String VEHICLE_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  // Enhanced RSSI and distance configuration
  static const int RSSI_AT_ONE_METER = -65;
  static const double PATH_LOSS_EXPONENT = 2.2; // Slightly higher for real-world conditions
  static const int HISTORY_BUFFER_SIZE = 15; // Larger buffer for better trend analysis
  static const double MAX_DETECTION_RANGE = 30.0; // Extended range for early detection
  static const double MIN_RELIABLE_DISTANCE = 1.5; // Minimum reliable distance

  // Collision detection thresholds
  static const double CRITICAL_DISTANCE = 3.0; // Critical collision zone
  static const double WARNING_DISTANCE = 8.0;  // Warning zone
  static const double SAFE_FOLLOWING_DISTANCE = 15.0; // Safe following distance
  static const double MIN_TTC_FOR_ALERT = 5.0; // Minimum time-to-collision for alert (seconds)

  final StreamController<List<DetectedVehicle>> _vehiclesController = StreamController<List<DetectedVehicle>>.broadcast();
  final StreamController<bool> _scanningController = StreamController<bool>.broadcast();
  final Map<String, DetectedVehicle> _trackedVehicles = {};
  final Map<String, List<int>> _rssiFilters = {}; // RSSI smoothing filters

  String _vehicleType = VehicleConfig.defaultType;
  double _mySpeed = 0.0; // My vehicle's speed (m/s)
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  
  Timer? _scanTimer;
  Timer? _cleanupTimer;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<Position>? _positionSubscription;

  Stream<List<DetectedVehicle>> get detectedVehicles => _vehiclesController.stream;
  Stream<bool> get isScanning => _scanningController.stream;

  void setVehicleType(String type) {
    if (VehicleConfig.vehicleSpecs.containsKey(type)) {
      _vehicleType = type;
    }
  }

  Future<void> startSmartDetection(BuildContext context) async {
    if (_isScanning) return;

    try {
      // Verify Bluetooth availability
      if (!(await FlutterBluePlus.isAvailable)) {
        throw Exception('Bluetooth not available');
      }
      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Please enable Bluetooth');
      }

      // Start location tracking for my vehicle's movement
      await _initializeLocationTracking();

      _isScanning = true;
      _scanningController.add(true);
      _trackedVehicles.clear();
      _rssiFilters.clear();

      // Start continuous scanning with collision analysis
      _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        await _performSmartScan(context);
      });

      // Start cleanup of stale vehicles
      _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _cleanupStaleVehicles();
      });

      await _performSmartScan(context);
    } catch (e) {
      _isScanning = false;
      _scanningController.add(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Smart detection error: $e')),
        );
      }
    }
  }

  Future<void> _initializeLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter
      ),
    ).listen((position) {
      _updateMyVehicleMovement(position);
    });
  }

  void _updateMyVehicleMovement(Position position) {
    final now = DateTime.now();
    
    if (_lastPosition != null && _lastPositionTime != null) {
      final timeDiff = now.difference(_lastPositionTime!).inMilliseconds / 1000.0;
      if (timeDiff > 0.1) { // Only update if enough time has passed
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        
        final instantSpeed = distance / timeDiff;
        _mySpeed = position.speed >= 0 ? position.speed : instantSpeed;
      }
    }
    
    _lastPosition = position;
    _lastPositionTime = now;
  }

  Future<void> _performSmartScan(BuildContext context) async {
    try {
      await _scanSubscription?.cancel();
      await FlutterBluePlus.startScan(timeout: const Duration(milliseconds: 300));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _processDetectedVehicle(result, context);
        }
      });
    } catch (e) {
      debugPrint('Smart scan error: $e');
    }
  }

  void _processDetectedVehicle(ScanResult result, BuildContext context) {
    final String vehicleId = result.device.remoteId.toString();
    final int rawRssi = result.rssi;
    final DateTime now = DateTime.now();

    // Apply RSSI filtering for more accurate distance calculation
    final int filteredRssi = _applyRssiFilter(vehicleId, rawRssi);
    final double distance = _calculateEnhancedDistance(filteredRssi);

    // Skip if distance is unreliable or too far
    if (distance < MIN_RELIABLE_DISTANCE || distance > MAX_DETECTION_RANGE) {
      return;
    }

    // Get or create vehicle tracking data
    final DetectedVehicle? existingVehicle = _trackedVehicles[vehicleId];
    final List<double> distanceHistory = [...(existingVehicle?.distanceHistory ?? [])];
    final List<DateTime> timeHistory = [...(existingVehicle?.timeHistory ?? [])];

    // Update history with new data point
    distanceHistory.add(distance);
    timeHistory.add(now);

    // Keep only recent history for analysis
    while (distanceHistory.length > HISTORY_BUFFER_SIZE) {
      distanceHistory.removeAt(0);
      timeHistory.removeAt(0);
    }

    // Calculate motion analytics
    final double velocity = _calculateVelocity(distanceHistory, timeHistory);
    final double acceleration = _calculateAcceleration(existingVehicle?.velocity ?? 0, velocity, timeHistory);

    // Perform collision risk analysis
    final CollisionMetrics? collisionMetrics = _analyzeCollisionRisk(
      distance, velocity, acceleration, distanceHistory
    );

    // Create updated vehicle object
    final DetectedVehicle updatedVehicle = DetectedVehicle(
      device: result.device,
      rssi: rawRssi,
      distance: distance,
      lastSeen: now,
      distanceHistory: distanceHistory,
      timeHistory: timeHistory,
      velocity: velocity,
      acceleration: acceleration,
      collisionMetrics: collisionMetrics,
      alertTriggered: existingVehicle?.alertTriggered ?? false,
    );

    _trackedVehicles[vehicleId] = updatedVehicle;

    // Trigger collision alert if necessary
    if (collisionMetrics != null && 
        collisionMetrics.riskLevel.index >= CollisionRisk.medium.index &&
        !updatedVehicle.alertTriggered &&
        context.mounted) {
      _triggerCollisionAlert(context, updatedVehicle);
    }

    // Emit updated vehicle list
    final List<DetectedVehicle> relevantVehicles = _trackedVehicles.values
        .where((v) => v.collisionMetrics != null && 
                     v.collisionMetrics!.riskLevel != CollisionRisk.none)
        .toList();

    _vehiclesController.add(relevantVehicles);
  }

  int _applyRssiFilter(String vehicleId, int rawRssi) {
    _rssiFilters.putIfAbsent(vehicleId, () => []);
    final filter = _rssiFilters[vehicleId]!;
    
    filter.add(rawRssi);
    if (filter.length > 5) filter.removeAt(0);

    // Use median filtering to remove spikes
    final sorted = List<int>.from(filter)..sort();
    return sorted[sorted.length ~/ 2];
  }

  double _calculateEnhancedDistance(int rssi) {
    // Enhanced distance calculation with environmental compensation
    double rawDistance = pow(10, (RSSI_AT_ONE_METER - rssi) / (10 * PATH_LOSS_EXPONENT)).toDouble();
    
    // Apply environmental correction factor based on RSSI strength
    double correctionFactor = 1.0;
    if (rssi > -50) {
      correctionFactor = 0.8; // Very close, likely line-of-sight
    } else if (rssi < -80) {
      correctionFactor = 1.3; // Distant or obstructed
    }
    
    return rawDistance * correctionFactor;
  }

  double _calculateVelocity(List<double> distances, List<DateTime> times) {
    if (distances.length < 3) return 0.0;

    // Use linear regression for more accurate velocity calculation
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final int n = min(distances.length, 8); // Use last 8 points for trend
    final baseTime = times[times.length - n].millisecondsSinceEpoch.toDouble();

    for (int i = times.length - n; i < times.length; i++) {
      final x = (times[i].millisecondsSinceEpoch - baseTime) / 1000.0; // seconds
      final y = distances[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope; // m/s (negative = approaching, positive = moving away)
  }

  double _calculateAcceleration(double prevVelocity, double currentVelocity, List<DateTime> times) {
    if (times.length < 2) return 0.0;
    
    final timeDiff = times.last.difference(times[times.length - 2]).inMilliseconds / 1000.0;
    if (timeDiff <= 0) return 0.0;
    
    return (currentVelocity - prevVelocity) / timeDiff;
  }

  CollisionMetrics? _analyzeCollisionRisk(
    double distance, 
    double velocity, 
    double acceleration,
    List<double> distanceHistory
  ) {
    // Only analyze if vehicle is approaching
    if (velocity >= -0.2) { // Not approaching significantly
      return CollisionMetrics(
        timeToCollision: double.infinity,
        relativeSpeed: velocity,
        collisionProbability: 0.0,
        riskLevel: CollisionRisk.none,
        riskDescription: 'Vehicle not approaching',
      );
    }

    // Calculate time to collision (TTC)
    double timeToCollision = double.infinity;
    if (velocity < -0.1) { // Approaching
      timeToCollision = -distance / velocity; // Negative velocity, so negate
    }

    // Calculate relative approach speed considering my vehicle's speed
    final double relativeSpeed = velocity.abs() + _mySpeed;

    // Calculate collision probability based on multiple factors
    double collisionProbability = 0.0;
    
    // Distance factor
    double distanceFactor = 1.0 - (distance / MAX_DETECTION_RANGE).clamp(0.0, 1.0);
    
    // Speed factor
    double speedFactor = (relativeSpeed / 30.0).clamp(0.0, 1.0); // Normalize to 30 m/s max
    
    // Acceleration factor (if accelerating towards me, higher risk)
    double accelFactor = acceleration < 0 ? (-acceleration / 5.0).clamp(0.0, 1.0) : 0.0;
    
    // Trend consistency (how consistently the vehicle is approaching)
    double trendFactor = _calculateTrendConsistency(distanceHistory);
    
    // Vehicle size factor (larger vehicles need more space)
    final vehicleSpecs = VehicleConfig.getSpecs(_vehicleType);
    double sizeFactor = (vehicleSpecs.width / 2.5).clamp(0.5, 1.5); // Normalize vehicle width
    
    collisionProbability = (distanceFactor * 0.35 + speedFactor * 0.25 + accelFactor * 0.15 + trendFactor * 0.15 + sizeFactor * 0.1);

    // Determine risk level
    CollisionRisk riskLevel = CollisionRisk.none;
    String riskDescription = '';

    if (distance <= CRITICAL_DISTANCE && timeToCollision <= 2.0) {
      riskLevel = CollisionRisk.critical;
      riskDescription = 'COLLISION IMMINENT! Distance: ${distance.toStringAsFixed(1)}m';
    } else if (distance <= WARNING_DISTANCE && timeToCollision <= 4.0) {
      riskLevel = CollisionRisk.high;
      riskDescription = 'HIGH RISK: Vehicle approaching fast! Distance: ${distance.toStringAsFixed(1)}m';
    } else if (timeToCollision <= MIN_TTC_FOR_ALERT && collisionProbability > 0.3) {
      riskLevel = CollisionRisk.medium;
      riskDescription = 'CAUTION: Vehicle approaching. Distance: ${distance.toStringAsFixed(1)}m';
    } else if (velocity < -2.0 && distance <= SAFE_FOLLOWING_DISTANCE) {
      riskLevel = CollisionRisk.low;
      riskDescription = 'Monitor: Fast-approaching vehicle detected';
    }

    return CollisionMetrics(
      timeToCollision: timeToCollision,
      relativeSpeed: relativeSpeed,
      collisionProbability: collisionProbability,
      riskLevel: riskLevel,
      riskDescription: riskDescription,
    );
  }

  double _calculateTrendConsistency(List<double> distances) {
    if (distances.length < 4) return 0.0;
    
    int approachingCount = 0;
    for (int i = 1; i < distances.length; i++) {
      if (distances[i] < distances[i-1]) {
        approachingCount++;
      }
    }
    
    return approachingCount / (distances.length - 1);
  }

  void _triggerCollisionAlert(BuildContext context, DetectedVehicle vehicle) {
    if (!context.mounted || vehicle.collisionMetrics == null) return;

    final metrics = vehicle.collisionMetrics!;
    
    // Mark alert as triggered
    _trackedVehicles[vehicle.device.remoteId.toString()] = vehicle.copyWith(alertTriggered: true);

    // Determine alert color and priority based on risk level
    Color alertColor = Colors.orange;
    Duration alertDuration = const Duration(seconds: 3);
    
    switch (metrics.riskLevel) {
      case CollisionRisk.critical:
        alertColor = Colors.red.shade900;
        alertDuration = const Duration(seconds: 8);
        break;
      case CollisionRisk.high:
        alertColor = Colors.red;
        alertDuration = const Duration(seconds: 5);
        break;
      case CollisionRisk.medium:
        alertColor = Colors.orange.shade700;
        alertDuration = const Duration(seconds: 4);
        break;
      case CollisionRisk.low:
        alertColor = Colors.yellow.shade700;
        alertDuration = const Duration(seconds: 3);
        break;
      default:
        return; // No alert for none risk
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              metrics.riskLevel == CollisionRisk.critical 
                ? Icons.dangerous 
                : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metrics.riskDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (metrics.timeToCollision.isFinite)
                    Text(
                      'Time to collision: ${metrics.timeToCollision.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: alertColor,
        duration: alertDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );

    // Reset alert flag after some time to allow re-alerting if risk persists
    Timer(const Duration(seconds: 10), () {
      final currentVehicle = _trackedVehicles[vehicle.device.remoteId.toString()];
      if (currentVehicle != null) {
        _trackedVehicles[vehicle.device.remoteId.toString()] = 
            currentVehicle.copyWith(alertTriggered: false);
      }
    });
  }

  void _cleanupStaleVehicles() {
    final now = DateTime.now();
    _trackedVehicles.removeWhere((id, vehicle) {
      final isStale = now.difference(vehicle.lastSeen).inSeconds > 8;
      if (isStale) {
        _rssiFilters.remove(id);
      }
      return isStale;
    });
  }

  Future<void> stopSmartDetection() async {
    _scanTimer?.cancel();
    _cleanupTimer?.cancel();
    await _scanSubscription?.cancel();
    await _positionSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _scanningController.add(false);
  }

  void dispose() {
    stopSmartDetection();
    _vehiclesController.close();
    _scanningController.close();
  }
}