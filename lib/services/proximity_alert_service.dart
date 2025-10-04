import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

// Configuration for different vehicle types and their widths
class VehicleConfig {
  static const Map<String, double> vehicleWidths = {
    'Compact SUV': 1.8,
    'Mid-size SUV': 2.0,
    'Full-size SUV': 2.2,
  };

  static const String defaultType = 'Mid-size SUV';
  static double getWidth(String type) => vehicleWidths[type] ?? vehicleWidths[defaultType]!;
}

class DetectedDevice {
  final BluetoothDevice device;
  final int rssi;
  final double distance;
  final DateTime lastSeen;
  final bool isMoving;
  final bool alertShown;
  final List<double> recentDistances;
  final bool isInRange;  // Whether the device is within proximity range

  DetectedDevice({
    required this.device,
    required this.rssi,
    required this.distance,
    required this.lastSeen,
    this.isMoving = false,
    this.alertShown = false,
    List<double>? recentDistances,
    bool? isInRange,
  }) : this.recentDistances = recentDistances ?? [distance],
       this.isInRange = isInRange ?? false;

  DetectedDevice copyWith({
    BluetoothDevice? device,
    int? rssi,
    double? distance,
    DateTime? lastSeen,
    bool? isMoving,
    bool? alertShown,
    List<double>? recentDistances,
    bool? isInRange,
  }) {
    return DetectedDevice(
      device: device ?? this.device,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      lastSeen: lastSeen ?? this.lastSeen,
      isMoving: isMoving ?? this.isMoving,
      alertShown: alertShown ?? this.alertShown,
      recentDistances: recentDistances ?? this.recentDistances,
      isInRange: isInRange ?? this.isInRange,
    );
  }
}

class ProximityAlertService {
  static const String VEHICLE_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  // RSSI and distance configuration
  static const int RSSI_AT_ONE_METER = -65;  // Calibrated RSSI at 1 meter
  static const double PATH_LOSS_EXPONENT = 2.0;  // Free space path loss
  static const int RSSI_BUFFER_SIZE = 10;  // Increased buffer for better averaging
  static const double MAX_VALID_DISTANCE = 20.0;  // Maximum distance to consider (meters)
  static const double MIN_VALID_DISTANCE = 2.0;   // Minimum distance to consider (meters)

  // Safety margins based on speed (in meters)
  static const double MARGIN_STATIONARY = 2.0;  // < 1 m/s
  static const double MARGIN_LOW_SPEED = 3.0;   // 1-5 m/s
  static const double MARGIN_HIGH_SPEED = 5.0;  // > 5 m/s

  final StreamController<List<DetectedDevice>> _nearbyVehiclesController = StreamController<List<DetectedDevice>>.broadcast();
  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  final Map<String, DetectedDevice> _detectedDevices = {};
  final Map<String, List<int>> _rssiBuffers = {};  // For RSSI smoothing

  String _selectedVehicleType = VehicleConfig.defaultType;
  double _currentSpeed = 0.0;  // meters/second
  Timer? _scanTimer;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<Position>? _positionSubscription;

  Stream<List<DetectedDevice>> get nearbyVehicles => _nearbyVehiclesController.stream;
  Stream<bool> get isScanning => _isScanningController.stream;

  // Method to update vehicle type
  void setVehicleType(String type) {
    if (VehicleConfig.vehicleWidths.containsKey(type)) {
      _selectedVehicleType = type;
    }
  }

  // Initialize speed tracking
  Future<void> _startSpeedTracking() async {
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

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((position) {
      _currentSpeed = position.speed >= 0 ? position.speed : 0.0;
    });
  }

  // Get safety margin based on current speed
  double _getSpeedBasedSafetyMargin() {
    if (_currentSpeed < 1) {
      return MARGIN_STATIONARY;
    } else if (_currentSpeed < 5) {
      return MARGIN_LOW_SPEED;
    }
    return MARGIN_HIGH_SPEED;
  }

  bool _isDeviceMoving(List<double> distances) {
    if (distances.length < 2) return false;

    // Calculate the standard deviation of recent distances
    double mean = distances.reduce((a, b) => a + b) / distances.length;
    double variance = distances.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / distances.length;
    double stdDev = sqrt(variance);

    // If standard deviation is above threshold, consider the device as moving
    return stdDev > 0.5; // Adjust this threshold based on testing
  }

  void _updateDetectedDevices(BluetoothDevice device, int rssi) {
    final String deviceId = device.remoteId.toString();
    final DateTime now = DateTime.now();

    // Initialize or update RSSI buffer for this device
    _rssiBuffers.putIfAbsent(deviceId, () => []);
    _rssiBuffers[deviceId]!.add(rssi);
    if (_rssiBuffers[deviceId]!.length > RSSI_BUFFER_SIZE) {
      _rssiBuffers[deviceId]!.removeAt(0);
    }

    // Apply Kalman filtering to RSSI values
    List<int> sortedRssi = List.from(_rssiBuffers[deviceId]!)..sort();
    // Remove extreme outliers (10% from each end)
    int trimCount = (_rssiBuffers[deviceId]!.length * 0.1).round();
    List<int> trimmedRssi = sortedRssi.sublist(
      trimCount,
      sortedRssi.length - trimCount
    );

    // Calculate smoothed RSSI using trimmed mean
    double smoothedRssi = trimmedRssi.reduce((a, b) => a + b) / trimmedRssi.length;

    // Skip outliers
    if ((rssi - smoothedRssi).abs() > 10) {
      return;
    }

    final double distance = _calculateDistanceFromRSSI(smoothedRssi.round());

    // Get existing device data or create new
    final DetectedDevice? existingDevice = _detectedDevices[deviceId];
    final List<double> recentDistances = [...(existingDevice?.recentDistances ?? [])];

    // Keep only last RSSI_BUFFER_SIZE distance measurements
    recentDistances.add(distance);
    if (recentDistances.length > RSSI_BUFFER_SIZE) {
      recentDistances.removeAt(0);
    }

    // Determine if device is moving
    final bool isMoving = _isDeviceMoving(recentDistances);

    // Check if device is within proximity range
    bool inRange = _isInProximityRange(distance);

    // Create updated device info
    final DetectedDevice updatedDevice = DetectedDevice(
      device: device,
      rssi: rssi,
      distance: distance,
      lastSeen: now,
      isMoving: isMoving,
      alertShown: existingDevice?.alertShown ?? false,
      recentDistances: recentDistances,
      isInRange: inRange,
    );

    _detectedDevices[deviceId] = updatedDevice;

    // Clean up old devices (older than 10 seconds)
    _detectedDevices.removeWhere((_, device) =>
      now.difference(device.lastSeen).inSeconds > 10);

    // Only emit moving devices that are within proximity range
    final relevantDevices = _detectedDevices.values.where((d) =>
      d.isMoving && _isInProximityRange(d.distance)
    ).toList();

    _nearbyVehiclesController.add(relevantDevices);
  }

  Future<void> startScanning(BuildContext context) async {
    if (_isScanning) return;

    try {
      // Check if Bluetooth is available and turned on
      if (!(await FlutterBluePlus.isAvailable)) {
        throw Exception('Bluetooth is not available on this device');
      }

      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Please turn on Bluetooth to detect nearby vehicles');
      }

      // Initialize speed tracking
      await _startSpeedTracking();

      _isScanning = true;
      _isScanningController.add(true);
      _detectedDevices.clear();
      _rssiBuffers.clear();

      // Start periodic scanning
      _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await _performScan(context);
      });

      // Perform initial scan
      await _performScan(context);
    } catch (e) {
      _isScanning = false;
      _isScanningController.add(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting vehicle detection: $e')),
        );
      }
    }
  }

  Future<void> _performScan(BuildContext context) async {
    try {
      // Cancel existing subscription if any
      await _scanSubscription?.cancel();

      // Start scanning for devices
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 1),
        withServices: [], // Temporarily remove UUID filter to see all devices
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty && context.mounted) {
          // Show debug information for found devices
          debugPrint('Found ${results.length} Bluetooth devices:');
          for (ScanResult result in results) {
            final distance = _calculateDistanceFromRSSI(result.rssi);
            debugPrint(
              'Device: ${result.device.remoteId}, '
              'Name: ${result.device.platformName}, '
              'Distance: ${distance.toStringAsFixed(2)}m'
            );

            // Update detected devices list
            _updateDetectedDevices(result.device, result.rssi);

            // Get the updated device info
            final device = _detectedDevices[result.device.remoteId.toString()];
            if (device != null &&
                device.isMoving &&
                _isInProximityRange(device.distance) &&
                !device.alertShown) {
              _showProximityAlert(context, device);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error during scan: $e');
    }
  }

  bool _isInProximityRange(double distance) {
    double safetyMargin = _getSpeedBasedSafetyMargin();
    double alertThreshold = VehicleConfig.getWidth(_selectedVehicleType) + safetyMargin;
    return distance <= alertThreshold;
  }

  double _calculateDistanceFromRSSI(int rssi) {
    // Using the log-distance path loss model with environmental factors
    // d = 10 ^ ((RSSI_1m - RSSI_measured) / (10 * n))
    // where n is the path loss exponent (2.0 for free space, higher for obstacles)
    
    // Calculate raw distance using path loss model
    double rawDistance = pow(10, (RSSI_AT_ONE_METER - rssi) / (10 * PATH_LOSS_EXPONENT)).toDouble();

    // Apply distance validation
    if (rawDistance < MIN_VALID_DISTANCE) {
      return MIN_VALID_DISTANCE;
    } else if (rawDistance > MAX_VALID_DISTANCE) {
      return double.infinity;  // Consider vehicle too far to be relevant
    }

    return rawDistance;
  }

  void _showProximityAlert(BuildContext context, DetectedDevice device) {
    if (!context.mounted || device.alertShown) return;

    // Update device to mark alert as shown
    _detectedDevices[device.device.remoteId.toString()] = device.copyWith(alertShown: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Warning: Moving vehicle detected nearby! Distance: ~${device.distance.toStringAsFixed(1)}m',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> stopScanning() async {
    _scanTimer?.cancel();
    await _scanSubscription?.cancel();
    await _positionSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _isScanningController.add(false);
  }

  void dispose() {
    stopScanning();
    _nearbyVehiclesController.close();
    _isScanningController.close();
  }
}