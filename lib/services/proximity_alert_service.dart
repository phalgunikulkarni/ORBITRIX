import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DetectedDevice {
  final BluetoothDevice device;
  final int rssi;
  final double distance;
  final DateTime lastSeen;
  final bool isMoving;
  final bool alertShown;
  final List<double> recentDistances;

  DetectedDevice({
    required this.device,
    required this.rssi,
    required this.distance,
    required this.lastSeen,
    this.isMoving = false,
    this.alertShown = false,
    List<double>? recentDistances,
  }) : this.recentDistances = recentDistances ?? [distance];

  DetectedDevice copyWith({
    BluetoothDevice? device,
    int? rssi,
    double? distance,
    DateTime? lastSeen,
    bool? isMoving,
    bool? alertShown,
    List<double>? recentDistances,
  }) {
    return DetectedDevice(
      device: device ?? this.device,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      lastSeen: lastSeen ?? this.lastSeen,
      isMoving: isMoving ?? this.isMoving,
      alertShown: alertShown ?? this.alertShown,
      recentDistances: recentDistances ?? this.recentDistances,
    );
  }
}

class ProximityAlertService {
  static const String VEHICLE_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const double MIN_PROXIMITY_METERS = 1.0;
  static const double MAX_PROXIMITY_METERS = 2.0;
  
  final StreamController<List<DetectedDevice>> _nearbyVehiclesController = StreamController<List<DetectedDevice>>.broadcast();
  final Map<String, DetectedDevice> _detectedDevices = {};
  Timer? _scanTimer;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<DetectedDevice>> get nearbyVehicles => _nearbyVehiclesController.stream;

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
    final double distance = _calculateDistanceFromRSSI(rssi);
    final DateTime now = DateTime.now();

    // Get existing device data or create new
    final DetectedDevice? existingDevice = _detectedDevices[deviceId];
    final List<double> recentDistances = [...(existingDevice?.recentDistances ?? [])];
    
    // Keep only last 5 distance measurements
    recentDistances.add(distance);
    if (recentDistances.length > 5) {
      recentDistances.removeAt(0);
    }

    // Determine if device is moving
    final bool isMoving = _isDeviceMoving(recentDistances);

    // Create updated device info
    final DetectedDevice updatedDevice = DetectedDevice(
      device: device,
      rssi: rssi,
      distance: distance,
      lastSeen: now,
      isMoving: isMoving,
      alertShown: existingDevice?.alertShown ?? false,
      recentDistances: recentDistances,
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

      _isScanning = true;
      _detectedDevices.clear();

      // Start periodic scanning
      _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await _performScan(context);
      });

      // Perform initial scan
      await _performScan(context);
    } catch (e) {
      _isScanning = false;
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
    return distance >= MIN_PROXIMITY_METERS && distance <= MAX_PROXIMITY_METERS;
  }

  double _calculateDistanceFromRSSI(int rssi) {
    // Convert RSSI to approximate distance
    // Using a simple path loss model: distance = 10 ^ ((Measured Power - RSSI) / (10 * N))
    // Where N is the path loss exponent (usually 2-4), and Measured Power is the RSSI at 1 meter
    const measuredPower = -69; // Typical value, adjust based on your device
    const pathLossExponent = 2.0;
    
    return pow(10, (measuredPower - rssi) / (10 * pathLossExponent)).toDouble();
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
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    stopScanning();
    _nearbyVehiclesController.close();
  }
}