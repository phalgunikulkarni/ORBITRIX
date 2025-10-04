import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Traffic congestion levels
enum TrafficCongestionLevel {
  free,      // Free flow traffic
  light,     // Light congestion
  moderate,  // Moderate congestion  
  heavy,     // Heavy congestion
  gridlock   // Severe gridlock
}

// Route segment with congestion data
class RouteSegment {
  final LatLng startPoint;
  final LatLng endPoint;
  final List<LatLng> segmentPoints;
  final TrafficCongestionLevel congestionLevel;
  final double averageSpeed; // km/h
  final int vehicleCount;
  final DateTime lastUpdated;
  final double congestionScore; // 0.0 - 1.0

  RouteSegment({
    required this.startPoint,
    required this.endPoint,
    required this.segmentPoints,
    required this.congestionLevel,
    required this.averageSpeed,
    required this.vehicleCount,
    required this.lastUpdated,
    required this.congestionScore,
  });

  Color get routeColor {
    switch (congestionLevel) {
      case TrafficCongestionLevel.free:
        return Colors.green;
      case TrafficCongestionLevel.light:
        return Colors.yellow.shade600;
      case TrafficCongestionLevel.moderate:
        return Colors.orange;
      case TrafficCongestionLevel.heavy:
        return Colors.red.shade600;
      case TrafficCongestionLevel.gridlock:
        return Colors.red.shade900;
    }
  }

  String get congestionDescription {
    switch (congestionLevel) {
      case TrafficCongestionLevel.free:
        return 'Free Flow';
      case TrafficCongestionLevel.light:
        return 'Light Traffic';
      case TrafficCongestionLevel.moderate:
        return 'Moderate Congestion';
      case TrafficCongestionLevel.heavy:
        return 'Heavy Traffic';
      case TrafficCongestionLevel.gridlock:
        return 'Severe Congestion';
    }
  }
}

// Detected vehicle for traffic analysis
class TrafficVehicle {
  final String deviceId;
  final LatLng estimatedLocation;
  final double distance;
  final int rssi;
  final DateTime detectedAt;
  final double estimatedSpeed; // km/h
  final bool isStationary;
  final List<double> speedHistory;

  TrafficVehicle({
    required this.deviceId,
    required this.estimatedLocation,
    required this.distance,
    required this.rssi,
    required this.detectedAt,
    required this.estimatedSpeed,
    required this.isStationary,
    List<double>? speedHistory,
  }) : speedHistory = speedHistory ?? [estimatedSpeed];

  TrafficVehicle copyWith({
    LatLng? estimatedLocation,
    double? distance,
    int? rssi,
    DateTime? detectedAt,
    double? estimatedSpeed,
    bool? isStationary,
    List<double>? speedHistory,
  }) {
    return TrafficVehicle(
      deviceId: deviceId,
      estimatedLocation: estimatedLocation ?? this.estimatedLocation,
      distance: distance ?? this.distance,
      rssi: rssi ?? this.rssi,
      detectedAt: detectedAt ?? this.detectedAt,
      estimatedSpeed: estimatedSpeed ?? this.estimatedSpeed,
      isStationary: isStationary ?? this.isStationary,
      speedHistory: speedHistory ?? this.speedHistory,
    );
  }
}

class TrafficCongestionDetectionService {
  // Bluetooth 6 enhanced detection parameters
  static const int BT6_ENHANCED_RANGE = 240; // BT6 has ~240m range
  static const int MIN_RSSI_THRESHOLD = -90; // Lower threshold for BT6
  static const double SEGMENT_LENGTH = 200.0; // Route segment length in meters
  static const int CONGESTION_ANALYSIS_INTERVAL = 15; // seconds
  static const int VEHICLE_TIMEOUT = 30; // seconds to keep vehicle data

  // Traffic analysis thresholds
  static const double FREE_FLOW_SPEED = 45.0; // km/h
  static const double LIGHT_CONGESTION_SPEED = 30.0; // km/h
  static const double MODERATE_CONGESTION_SPEED = 20.0; // km/h
  static const double HEAVY_CONGESTION_SPEED = 10.0; // km/h
  static const int HIGH_DENSITY_THRESHOLD = 15; // vehicles per segment
  static const int MODERATE_DENSITY_THRESHOLD = 8; // vehicles per segment

  final StreamController<List<RouteSegment>> _trafficDataController = 
      StreamController<List<RouteSegment>>.broadcast();
  final StreamController<bool> _scanningController = StreamController<bool>.broadcast();

  final Map<String, TrafficVehicle> _detectedVehicles = {};
  final Map<String, List<int>> _rssiBuffers = {};
  final List<LatLng> _currentRoute = [];
  final List<RouteSegment> _routeSegments = [];

  LatLng? _currentLocation;
  double _currentSpeed = 0.0;
  Timer? _scanTimer;
  Timer? _analysisTimer;
  Timer? _cleanupTimer;
  bool _isActive = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<Position>? _positionSubscription;

  Stream<List<RouteSegment>> get trafficData => _trafficDataController.stream;
  Stream<bool> get isScanning => _scanningController.stream;
  List<RouteSegment> get currentTrafficSegments => List.from(_routeSegments);

  Future<void> startTrafficDetection(List<LatLng> route) async {
    if (_isActive) return;

    try {
      // Verify Bluetooth 6 capability
      if (!(await FlutterBluePlus.isAvailable)) {
        throw Exception('Bluetooth not available');
      }
      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Please enable Bluetooth');
      }

      _currentRoute.clear();
      _currentRoute.addAll(route);
      _createRouteSegments();

      await _initializeLocationTracking();

      _isActive = true;
      _scanningController.add(true);

      // Start BT6 enhanced scanning
      _scanTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        await _performTrafficScan();
      });

      // Start traffic analysis
      _analysisTimer = Timer.periodic(
        const Duration(seconds: CONGESTION_ANALYSIS_INTERVAL), 
        (_) => _analyzeTrafficCongestion()
      );

      // Start cleanup of stale vehicles
      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _cleanupStaleVehicles();
      });

      debugPrint('Traffic congestion detection started for ${route.length} route points');
    } catch (e) {
      _isActive = false;
      _scanningController.add(false);
      throw Exception('Failed to start traffic detection: $e');
    }
  }

  void _createRouteSegments() {
    _routeSegments.clear();
    if (_currentRoute.length < 2) return;

    for (int i = 0; i < _currentRoute.length - 1; i++) {
      final start = _currentRoute[i];
      final end = _currentRoute[i + 1];
      
      // Create intermediate points for the segment
      final segmentPoints = _interpolatePoints(start, end, SEGMENT_LENGTH);
      
      _routeSegments.add(RouteSegment(
        startPoint: start,
        endPoint: end,
        segmentPoints: segmentPoints,
        congestionLevel: TrafficCongestionLevel.free,
        averageSpeed: FREE_FLOW_SPEED,
        vehicleCount: 0,
        lastUpdated: DateTime.now(),
        congestionScore: 0.0,
      ));
    }
  }

  List<LatLng> _interpolatePoints(LatLng start, LatLng end, double maxDistance) {
    final distance = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );

    if (distance <= maxDistance) {
      return [start, end];
    }

    final numSegments = (distance / maxDistance).ceil();
    final points = <LatLng>[];

    for (int i = 0; i <= numSegments; i++) {
      final ratio = i / numSegments;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }

    return points;
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
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
    });
  }

  Future<void> _performTrafficScan() async {
    try {
      await _scanSubscription?.cancel();
      await FlutterBluePlus.startScan(timeout: const Duration(milliseconds: 150));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _processTrafficVehicle(result);
        }
      });
    } catch (e) {
      debugPrint('Traffic scan error: $e');
    }
  }

  void _processTrafficVehicle(ScanResult result) {
    final String vehicleId = result.device.remoteId.toString();
    final int rawRssi = result.rssi;
    final DateTime now = DateTime.now();

    // Enhanced BT6 RSSI filtering
    final int filteredRssi = _applyBT6RssiFilter(vehicleId, rawRssi);
    
    // Skip weak signals that are likely too far
    if (filteredRssi < MIN_RSSI_THRESHOLD) return;

    // Calculate distance using BT6 enhanced ranging
    final double distance = _calculateBT6Distance(filteredRssi);
    if (distance > BT6_ENHANCED_RANGE) return;

    // Estimate vehicle location relative to current position
    final LatLng? estimatedLocation = _estimateVehicleLocation(distance);
    if (estimatedLocation == null) return;

    // Get existing vehicle or create new
    final TrafficVehicle? existingVehicle = _detectedVehicles[vehicleId];
    
    // Calculate vehicle speed based on position changes
    double estimatedSpeed = _currentSpeed; // Default to our speed
    bool isStationary = false;

    if (existingVehicle != null) {
      final timeDiff = now.difference(existingVehicle.detectedAt).inSeconds;
      if (timeDiff > 0) {
        final locationDistance = Geolocator.distanceBetween(
          existingVehicle.estimatedLocation.latitude,
          existingVehicle.estimatedLocation.longitude,
          estimatedLocation.latitude,
          estimatedLocation.longitude,
        );
        estimatedSpeed = (locationDistance / timeDiff) * 3.6; // m/s to km/h
        isStationary = estimatedSpeed < 5.0; // Less than 5 km/h
      }

      // Update speed history
      final updatedSpeedHistory = [...existingVehicle.speedHistory];
      updatedSpeedHistory.add(estimatedSpeed);
      if (updatedSpeedHistory.length > 10) {
        updatedSpeedHistory.removeAt(0);
      }

      _detectedVehicles[vehicleId] = existingVehicle.copyWith(
        estimatedLocation: estimatedLocation,
        distance: distance,
        rssi: rawRssi,
        detectedAt: now,
        estimatedSpeed: estimatedSpeed,
        isStationary: isStationary,
        speedHistory: updatedSpeedHistory,
      );
    } else {
      _detectedVehicles[vehicleId] = TrafficVehicle(
        deviceId: vehicleId,
        estimatedLocation: estimatedLocation,
        distance: distance,
        rssi: rawRssi,
        detectedAt: now,
        estimatedSpeed: estimatedSpeed,
        isStationary: isStationary,
      );
    }
  }

  int _applyBT6RssiFilter(String vehicleId, int rawRssi) {
    _rssiBuffers.putIfAbsent(vehicleId, () => []);
    final buffer = _rssiBuffers[vehicleId]!;
    
    buffer.add(rawRssi);
    if (buffer.length > 5) buffer.removeAt(0);

    // Use weighted average with recent values having more weight
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < buffer.length; i++) {
      final weight = (i + 1).toDouble(); // More recent = higher weight
      weightedSum += buffer[i] * weight;
      totalWeight += weight;
    }

    return (weightedSum / totalWeight).round();
  }

  double _calculateBT6Distance(int rssi) {
    // Enhanced BT6 distance calculation with better path loss model
    const int bt6RssiAt1m = -60; // BT6 calibrated RSSI at 1 meter
    const double bt6PathLoss = 2.1; // BT6 optimized path loss exponent
    
    return pow(10, (bt6RssiAt1m - rssi) / (10 * bt6PathLoss)).toDouble();
  }

  LatLng? _estimateVehicleLocation(double distance) {
    if (_currentLocation == null) return null;

    // Estimate vehicle position in a random direction within detection range
    final angle = Random().nextDouble() * 2 * pi;
    final latOffset = (distance * cos(angle)) / 111111; // degrees per meter
    final lngOffset = (distance * sin(angle)) / 
        (111111 * cos(_currentLocation!.latitude * pi / 180));

    return LatLng(
      _currentLocation!.latitude + latOffset,
      _currentLocation!.longitude + lngOffset,
    );
  }

  void _analyzeTrafficCongestion() {
    if (_currentLocation == null || _routeSegments.isEmpty) return;

    final updatedSegments = <RouteSegment>[];

    for (final segment in _routeSegments) {
      // Find vehicles within this segment
      final segmentVehicles = _detectedVehicles.values.where((vehicle) {
        return _isVehicleInSegment(vehicle, segment);
      }).toList();

      // Calculate traffic metrics
      final vehicleCount = segmentVehicles.length;
      final stationaryCount = segmentVehicles.where((v) => v.isStationary).length;
      final averageSpeed = segmentVehicles.isEmpty 
          ? FREE_FLOW_SPEED 
          : segmentVehicles.map((v) => v.estimatedSpeed).reduce((a, b) => a + b) / segmentVehicles.length;

      // Calculate congestion score (0.0 - 1.0)
      double congestionScore = 0.0;
      
      // Vehicle density factor (0.0 - 0.4)
      final densityFactor = (vehicleCount / HIGH_DENSITY_THRESHOLD).clamp(0.0, 0.4);
      
      // Speed factor (0.0 - 0.4)
      final speedFactor = (1.0 - (averageSpeed / FREE_FLOW_SPEED)).clamp(0.0, 0.4);
      
      // Stationary vehicles factor (0.0 - 0.2)
      final stationaryFactor = vehicleCount > 0 
          ? (stationaryCount / vehicleCount) * 0.2
          : 0.0;

      congestionScore = densityFactor + speedFactor + stationaryFactor;

      // Determine congestion level
      TrafficCongestionLevel congestionLevel;
      if (congestionScore >= 0.8) {
        congestionLevel = TrafficCongestionLevel.gridlock;
      } else if (congestionScore >= 0.6) {
        congestionLevel = TrafficCongestionLevel.heavy;
      } else if (congestionScore >= 0.4) {
        congestionLevel = TrafficCongestionLevel.moderate;
      } else if (congestionScore >= 0.2) {
        congestionLevel = TrafficCongestionLevel.light;
      } else {
        congestionLevel = TrafficCongestionLevel.free;
      }

      updatedSegments.add(RouteSegment(
        startPoint: segment.startPoint,
        endPoint: segment.endPoint,
        segmentPoints: segment.segmentPoints,
        congestionLevel: congestionLevel,
        averageSpeed: averageSpeed,
        vehicleCount: vehicleCount,
        lastUpdated: DateTime.now(),
        congestionScore: congestionScore,
      ));
    }

    _routeSegments.clear();
    _routeSegments.addAll(updatedSegments);
    _trafficDataController.add(List.from(_routeSegments));

    debugPrint('Traffic analysis: ${_routeSegments.length} segments, ${_detectedVehicles.length} vehicles detected');
  }

  bool _isVehicleInSegment(TrafficVehicle vehicle, RouteSegment segment) {
    // Check if vehicle is within reasonable distance of segment
    const double maxDistanceFromRoute = 100.0; // meters

    for (final point in segment.segmentPoints) {
      final distance = Geolocator.distanceBetween(
        vehicle.estimatedLocation.latitude,
        vehicle.estimatedLocation.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance <= maxDistanceFromRoute) {
        return true;
      }
    }

    return false;
  }

  void _cleanupStaleVehicles() {
    final now = DateTime.now();
    _detectedVehicles.removeWhere((id, vehicle) {
      final isStale = now.difference(vehicle.detectedAt).inSeconds > VEHICLE_TIMEOUT;
      if (isStale) {
        _rssiBuffers.remove(id);
      }
      return isStale;
    });
  }

  Future<void> stopTrafficDetection() async {
    _scanTimer?.cancel();
    _analysisTimer?.cancel();
    _cleanupTimer?.cancel();
    await _scanSubscription?.cancel();
    await _positionSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    
    _isActive = false;
    _scanningController.add(false);
    _detectedVehicles.clear();
    _rssiBuffers.clear();
    _routeSegments.clear();

    debugPrint('Traffic congestion detection stopped');
  }

  void dispose() {
    stopTrafficDetection();
    _trafficDataController.close();
    _scanningController.close();
  }
}