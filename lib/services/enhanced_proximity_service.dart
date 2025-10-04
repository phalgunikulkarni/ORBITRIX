import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  final bool isBluetooth6;  // Flag for Bluetooth 6.0 devices
  final List<double> recentDistances;

  DetectedDevice({
    required this.device,
    required this.rssi,
    required this.distance,
    required this.lastSeen,
    this.isMoving = false,
    this.alertShown = false,
    this.isBluetooth6 = false,
    List<double>? recentDistances,
  }) : this.recentDistances = recentDistances ?? [distance];

  DetectedDevice copyWith({
    BluetoothDevice? device,
    int? rssi,
    double? distance,
    DateTime? lastSeen,
    bool? isMoving,
    bool? alertShown,
    bool? isBluetooth6,
    List<double>? recentDistances,
  }) {
    return DetectedDevice(
      device: device ?? this.device,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      lastSeen: lastSeen ?? this.lastSeen,
      isMoving: isMoving ?? this.isMoving,
      alertShown: alertShown ?? this.alertShown,
      isBluetooth6: isBluetooth6 ?? this.isBluetooth6,
      recentDistances: recentDistances ?? this.recentDistances,
    );
  }
}

class EnhancedProximityService {
  // Constants for distance calculation
  static const double PROXIMITY_THRESHOLD = 3.0;  // Alert threshold in meters
  static const int RSSI_AT_ONE_METER_BT6 = -60;  // Calibrated for Bluetooth 6.0
  static const int RSSI_AT_ONE_METER_BLE = -65;  // Calibrated for BLE
  static const double PATH_LOSS_EXPONENT_BT6 = 1.8;  // Better signal propagation for BT 6.0
  static const double PATH_LOSS_EXPONENT_BLE = 2.0;  // Standard free space path loss
  static const int RSSI_BUFFER_SIZE = 10;

  final StreamController<List<DetectedDevice>> _nearbyVehiclesController = 
      StreamController<List<DetectedDevice>>.broadcast();
  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  final Map<String, DetectedDevice> _detectedDevices = {};
  final Map<String, List<int>> _rssiBuffers = {};

  Timer? _scanTimer;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<DetectedDevice>> get nearbyVehicles => _nearbyVehiclesController.stream;
  Stream<bool> get isScanning => _isScanningController.stream;

  Future<void> startScanning(BuildContext context) async {
    if (_isScanning) return;

    try {
      if (!(await FlutterBluePlus.isAvailable)) {
        throw Exception('Bluetooth is not available on this device');
      }

      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Please turn on Bluetooth to detect nearby vehicles');
      }

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
      await _scanSubscription?.cancel();

      // Start scanning with specific filters for vehicle service
      // Start scanning with enhanced settings for BT6 detection
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 1),
        // Using default scan mode for better compatibility
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty && context.mounted) {
          for (ScanResult result in results) {
            // Check for Bluetooth 6.0 capability using manufacturer data
            bool isBT6 = _isBluetooth6Device(result.advertisementData.manufacturerData);
            
            double distance = _calculateDistance(result.rssi, isBT6);
            debugPrint(
              'Device: ${result.device.remoteId}, '
              'Name: ${result.device.platformName}, '
              'BT6: $isBT6, '
              'Distance: ${distance.toStringAsFixed(2)}m'
            );

            _updateDetectedDevices(result.device, result.rssi, isBT6);
          }
        }
      });
    } catch (e) {
      debugPrint('Error during scan: $e');
    }
  }

  bool _isBluetooth6Device(Map<int, List<int>> manufacturerData) {
    // Check for specific Bluetooth 6.0 feature flags in manufacturer data
    if (manufacturerData.isEmpty) return false;

    // Check for core Bluetooth 6.0 features in manufacturer data
    for (var entry in manufacturerData.entries) {
      List<int> data = entry.value;
      if (data.length < 3) continue;

      // Check for BT6 specific bits in the feature flags
      // Byte 0-1: Company ID
      // Byte 2: Feature Flags
      // - Bit 7: LE Coded PHY Support (BT5+)
      // - Bit 6: Extended Advertising Support
      // - Bit 5: Periodic Advertising Support
      // - Bit 4: Channel Selection Algorithm #2
      // - Bit 3: Power Class 1 Support
      // All these features together indicate BT6 capability
      int featureFlags = data[2];
      bool hasLECodedPHY = (featureFlags & 0x80) != 0;
      bool hasExtendedAdv = (featureFlags & 0x40) != 0;
      bool hasPeriodicAdv = (featureFlags & 0x20) != 0;
      bool hasCSA2 = (featureFlags & 0x10) != 0;
      bool hasPowerClass1 = (featureFlags & 0x08) != 0;

      // Device must support all key BT6 features
      if (hasLECodedPHY && hasExtendedAdv && hasPeriodicAdv && hasCSA2 && hasPowerClass1) {
        return true;
      }

      // Check for specific manufacturer implementations
      if (entry.key == 0x004C) { // Apple
        // Check for Apple's BT6 implementation markers
        if (data.length >= 4 && data[3] >= 0x0C) { // Version 12+ indicates BT6
          return true;
        }
      } else if (entry.key == 0x0075) { // Samsung
        // Check for Samsung's BT6 implementation markers
        if (data.length >= 5 && data[4] >= 0x06) { // Version 6+ indicates BT6
          return true;
        }
      }
    }
    return false;
  }

  void _updateDetectedDevices(BluetoothDevice device, int rssi, bool isBT6) {
    final String deviceId = device.remoteId.toString();
    final DateTime now = DateTime.now();

    // Initialize or update RSSI buffer with timestamps
    _rssiBuffers.putIfAbsent(deviceId, () => []);
    _rssiBuffers[deviceId]!.add(rssi);
    if (_rssiBuffers[deviceId]!.length > (isBT6 ? RSSI_BUFFER_SIZE * 2 : RSSI_BUFFER_SIZE)) {
      _rssiBuffers[deviceId]!.removeAt(0);
    }

    // Enhanced signal processing for BT6 devices
    List<int> sortedRssi = List.from(_rssiBuffers[deviceId]!)..sort();
    int trimCount = (_rssiBuffers[deviceId]!.length * (isBT6 ? 0.15 : 0.1)).round();
    List<int> trimmedRssi = sortedRssi.sublist(
      trimCount,
      sortedRssi.length - trimCount
    );

    // Apply weighted moving average for BT6 devices
    if (isBT6 && trimmedRssi.length > 3) {
      double weightedSum = 0;
      double weightSum = 0;
      for (int i = 0; i < trimmedRssi.length; i++) {
        double weight = (i + 1).toDouble();  // More recent values get higher weights
        weightedSum += trimmedRssi[i] * weight;
        weightSum += weight;
      }
      trimmedRssi = [(weightedSum / weightSum).round()];
    }

    // Calculate smoothed RSSI
    double smoothedRssi = trimmedRssi.reduce((a, b) => a + b) / trimmedRssi.length;
    double distance = _calculateDistance(smoothedRssi.round(), isBT6);

    // Get existing device data or create new
    final DetectedDevice? existingDevice = _detectedDevices[deviceId];
    final List<double> recentDistances = [...(existingDevice?.recentDistances ?? [])];

    recentDistances.add(distance);
    if (recentDistances.length > RSSI_BUFFER_SIZE) {
      recentDistances.removeAt(0);
    }

    bool isMoving = _isDeviceMoving(recentDistances);
    final DetectedDevice updatedDevice = DetectedDevice(
      device: device,
      rssi: rssi,
      distance: distance,
      lastSeen: now,
      isMoving: isMoving,
      alertShown: existingDevice?.alertShown ?? false,
      isBluetooth6: isBT6,
      recentDistances: recentDistances,
    );

    _detectedDevices[deviceId] = updatedDevice;

    // Clean up old devices
    _detectedDevices.removeWhere((_, device) =>
      now.difference(device.lastSeen).inSeconds > 10);

    // Sort devices by priority (BT6 first, then by distance)
    final relevantDevices = _detectedDevices.values
      .where((d) => d.isMoving && d.distance <= PROXIMITY_THRESHOLD)
      .toList()
      ..sort((a, b) {
        if (a.isBluetooth6 != b.isBluetooth6) {
          return a.isBluetooth6 ? -1 : 1;  // BT6 devices first
        }
        return a.distance.compareTo(b.distance);  // Then by distance
      });

    _nearbyVehiclesController.add(relevantDevices);
  }

  double _calculateDistance(int rssi, bool isBT6) {
    // Enhanced distance calculation with environmental factors
    int rssiAtOneMeter = isBT6 ? RSSI_AT_ONE_METER_BT6 : RSSI_AT_ONE_METER_BLE;
    double pathLossExponent = isBT6 ? PATH_LOSS_EXPONENT_BT6 : PATH_LOSS_EXPONENT_BLE;

    // Apply environmental correction factor
    double environmentalFactor = 1.0;
    if (rssi > -50) {
      // Strong signal, likely line-of-sight
      environmentalFactor = 0.8;
    } else if (rssi < -80) {
      // Weak signal, likely obstructed
      environmentalFactor = 1.2;
    }

    // Adjust path loss exponent based on signal strength for BT6
    if (isBT6) {
      if (rssi > -60) {
        // Better performance in close range
        pathLossExponent *= 0.9;
      } else if (rssi < -90) {
        // Compensate for high-distance degradation
        pathLossExponent *= 1.1;
      }
    }

    // Calculate base distance using adjusted path loss model
    double distance = pow(10, (rssiAtOneMeter - rssi) / (10 * pathLossExponent)).toDouble();
    
    // Apply environmental correction
    distance *= environmentalFactor;

    // Add stability constraints
    return max(0.1, min(50.0, distance));  // Limit range to realistic values
  }

  bool _isDeviceMoving(List<double> distances) {
    if (distances.length < 2) return false;

    double mean = distances.reduce((a, b) => a + b) / distances.length;
    double variance = distances.map((d) => pow(d - mean, 2))
                             .reduce((a, b) => a + b) / distances.length;
    double stdDev = sqrt(variance);

    return stdDev > 0.3;  // Adjusted threshold for more sensitive movement detection
  }

  void setVehicleType(String type) {
    if (VehicleConfig.vehicleWidths.containsKey(type)) {
      // Vehicle type setting logic can be added here when needed
    }
  }

  Future<void> stopScanning() async {
    _scanTimer?.cancel();
    await _scanSubscription?.cancel();
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