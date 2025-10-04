import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'services/proximity_alert_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class RouteTrackingScreen extends StatefulWidget {
  const RouteTrackingScreen({super.key});

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
  final ProximityAlertService _proximityService = ProximityAlertService();
  
  LatLng _currentPosition = const LatLng(12.9716, 77.5946); // Default: Bangalore
  LatLng? _destinationPosition;
  List<LatLng> _routePoints = [];
  List<String> _directions = [];
  String? _eta;
  String? _distance;
  Timer? _locationUpdateTimer;
  bool _isSearching = false;
  int _currentDirectionIndex = 0;
  double _bearing = 0.0;
  List<DetectedDevice> _nearbyDevices = [];

  IconData _getDirectionIcon(String direction) {
    final lowerDirection = direction.toLowerCase();
    if (lowerDirection.contains('left')) {
      return Icons.turn_left;
    } else if (lowerDirection.contains('right')) {
      return Icons.turn_right;
    } else if (lowerDirection.contains('u-turn') || lowerDirection.contains('uturn')) {
      return Icons.u_turn_left;
    } else if (lowerDirection.contains('merge') || lowerDirection.contains('exit')) {
      return Icons.merge;
    } else if (lowerDirection.contains('continue') || lowerDirection.contains('straight')) {
      return Icons.straight;
    } else {
      return Icons.navigation;
    }
  }

  String _getSimplifiedDirection(String direction) {
    final lowerDirection = direction.toLowerCase();
    if (lowerDirection.contains('left')) {
      return 'Turn Left';
    } else if (lowerDirection.contains('right')) {
      return 'Turn Right';
    } else if (lowerDirection.contains('u-turn') || lowerDirection.contains('uturn')) {
      return 'Make U-Turn';
    } else if (lowerDirection.contains('merge')) {
      return 'Merge';
    } else if (lowerDirection.contains('exit')) {
      return 'Take Exit';
    } else if (lowerDirection.contains('continue') || lowerDirection.contains('straight')) {
      return 'Continue Straight';
    } else {
      return direction;
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    // Check and request Bluetooth permissions
    Map<ph.Permission, ph.PermissionStatus> statuses = await [
      ph.Permission.bluetooth,
      ph.Permission.bluetoothScan,
      ph.Permission.bluetoothConnect,
      ph.Permission.location,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (status != ph.PermissionStatus.granted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth and Location permissions are required for vehicle detection'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return allGranted;
  }

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    // Only request permissions initially, don't start scanning yet
    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _destinationController.dispose();
    _mapController.dispose();
    _proximityService.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    // Update location every 2 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _updateCurrentLocation();
      if (_destinationPosition != null) {
        _updateNavigationProgress();
      }
    });
    // Get initial location
    _updateCurrentLocation();
  }

  Future<void> _updateCurrentLocation() async {
    final location = Location();
    try {
      final userLocation = await location.getLocation();
      if (!mounted) return;

      final newPosition = LatLng(
        userLocation.latitude ?? _currentPosition.latitude,
        userLocation.longitude ?? _currentPosition.longitude,
      );

      // Calculate bearing for smooth rotation
      if (_currentPosition != newPosition) {
        _bearing = _calculateBearing(_currentPosition, newPosition);
      }

      setState(() {
        _currentPosition = newPosition;
      });

      // If we have a destination, update the route and recenter map
      if (_destinationPosition != null) {
        _updateRoute();
        // Center and rotate map to follow current location
        _mapController.move(_currentPosition, _mapController.zoom);
        _mapController.rotate(_bearing);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }

  void _updateNavigationProgress() {
    if (_routePoints.isEmpty || _directions.isEmpty) return;

    // Find the closest point on route
    int closestPointIndex = _findClosestPointIndex();
    
    // Calculate distance to next turn point
    double distanceToNextTurn = _calculateDistance(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _routePoints[closestPointIndex].latitude,
      _routePoints[closestPointIndex].longitude,
    );

    // Update current direction if we're close enough to the next turn point
    if (distanceToNextTurn < 0.03) { // 30 meters threshold
      setState(() {
        if (_currentDirectionIndex < _directions.length - 1) {
          _currentDirectionIndex++;
          // Show turn notification
          _showTurnNotification(_directions[_currentDirectionIndex]);
        }
      });
    }
  }

  int _findClosestPointIndex() {
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _routePoints.length; i++) {
      double distance = _calculateDistance(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _routePoints[i].latitude,
        _routePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    double lat1 = _toRadians(from.latitude);
    double lon1 = _toRadians(from.longitude);
    double lat2 = _toRadians(to.latitude);
    double lon2 = _toRadians(to.longitude);

    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);
    return (degrees(bearing) + 360) % 360;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  double degrees(double rad) {
    return rad * 180 / pi;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  void _showTurnNotification(String instruction) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          instruction,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _searchDestination() async {
    final address = _destinationController.text;
    if (address.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('No locations found');
      }

      final destination = LatLng(locations.first.latitude, locations.first.longitude);
      setState(() {
        _destinationPosition = destination;
        _isSearching = false;
        _currentDirectionIndex = 0; // Reset navigation progress
      });

      await _updateRoute();
      _fitMapToBounds();

      // Start BLE scanning after destination is set
      if (await _checkAndRequestPermissions()) {
        _proximityService.startScanning(context);
        // Listen to nearby devices
        _proximityService.nearbyVehicles.listen((devices) {
          setState(() {
            _nearbyDevices = devices;
          });
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location: $e')),
      );
    }
  }

  Future<void> _updateRoute() async {
    if (_destinationPosition == null) return;

    try {
      final response = await http.get(Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_currentPosition.longitude},${_currentPosition.latitude};'
        '${_destinationPosition!.longitude},${_destinationPosition!.latitude}'
        '?overview=full&steps=true&annotations=true',
      ));

      if (response.statusCode != 200) {
        throw Exception('Failed to calculate route');
      }

      final data = json.decode(response.body);
      if (data['code'] != 'Ok') {
        throw Exception(data['message'] ?? 'Route calculation failed');
      }

      final route = data['routes'][0];
      final geometry = route['geometry'];
      final legs = route['legs'] as List;
      final steps = legs[0]['steps'] as List;
      
      final points = _decodePolyline(geometry);
      final duration = (route['duration'] as num).toDouble();
      final distance = (route['distance'] as num).toDouble();
      
      // Format directions with distances
      final directions = <String>[];
      for (final step in steps) {
        final maneuver = step['maneuver'] as Map<String, dynamic>;
        final stepDistance = (step['distance'] as num).toDouble();
        String instruction = maneuver['text']?.toString() ?? 'Continue straight';
        instruction += ' (${_formatDistance(stepDistance)})';
        directions.add(instruction);
      }

      setState(() {
        _routePoints = points;
        _directions = directions;
        _distance = _formatDistance(distance);
        _eta = _formatDuration(duration);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating route: $e')),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final now = DateTime.now();
    final arrival = now.add(duration);
    return DateFormat('HH:mm').format(arrival);
  }

  void _fitMapToBounds() {
    if (_destinationPosition == null) return;

    final bounds = LatLngBounds.fromPoints([_currentPosition, _destinationPosition!]);
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Tracking'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          hintText: 'Enter destination address',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onSubmitted: (_) => _searchDestination(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchDestination,
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
                if (_eta != null && _distance != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('ETA: $_eta'),
                      const SizedBox(width: 16),
                      Icon(Icons.straight, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(_distance!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 16,
                    keepAlive: true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.orbitrx',
                    ),
                    // Vehicle markers layer
                    MarkerLayer(
                      markers: [
                        // Detected device markers (only for moving vehicles)
                        ..._nearbyDevices.where((device) => device.isMoving).map((device) {
                          // Calculate approximate position based on distance and movement
                          final angle = Random().nextDouble() * 2 * pi;
                          final lat = _currentPosition.latitude + 
                              (device.distance * cos(angle)) / 111111;
                          final lng = _currentPosition.longitude + 
                              (device.distance * sin(angle)) / (111111 * cos(_currentPosition.latitude * pi / 180));
                          
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 30,
                            height: 30,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Moving Vehicle Detected\n'
                                      'Name: ${device.device.platformName}\n'
                                      'Distance: ${device.distance.toStringAsFixed(1)}m\n'
                                      'Signal Strength: ${device.rssi} dBm'
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: device.distance >= 1.0 && device.distance <= 2.0
                                      ? Colors.red.withOpacity(0.7)
                                      : Colors.orange.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    // Route polyline layer
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    // Destination marker layer
                    if (_destinationPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _destinationPosition!,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    // Current location marker layer (on top)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 40,
                          height: 40,
                          child: Transform.rotate(
                            angle: _bearing * (pi / 180),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Recenter button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'proximity',
                        onPressed: () {
                          _proximityService.startScanning(context);
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.bluetooth_searching, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'location',
                        onPressed: () {
                          _mapController.move(_currentPosition, 22); // Maximum zoom level for highest magnification
                          _mapController.rotate(_bearing);
                        },
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (_directions.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Icon(
                              _getDirectionIcon(_directions[_currentDirectionIndex]),
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Next Turn',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getSimplifiedDirection(_directions[_currentDirectionIndex]),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}