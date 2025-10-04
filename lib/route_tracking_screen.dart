import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'services/proximity_alert_service.dart';
import 'services/smart_collision_detection_service.dart';
import 'services/traffic_congestion_detection_service.dart';
import 'models/place_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'services/google_places_service.dart';

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
  List<Place> _searchResults = [];
  LatLng? _destinationPosition;
  List<LatLng> _routePoints = [];
  List<String> _directions = [];
  String? _eta;
  String? _distance;
  Timer? _locationUpdateTimer;
  bool _isSearching = false;
  bool _isNavigationStarted = false;
  int _currentDirectionIndex = 0;
  double _bearing = 0.0;
  List<DetectedDevice> _nearbyDevices = [];
  List<DetectedVehicle> _smartDetectedVehicles = [];
  List<RouteSegment> _trafficSegments = [];

  // Services
  final SmartCollisionDetectionService _smartCollisionService = SmartCollisionDetectionService();
  final TrafficCongestionDetectionService _trafficService = TrafficCongestionDetectionService();

  // Google Places API Key
  final String _googleApiKey = 'AIzaSyCx8UgZDXtJ-w9RoIl2-QHn8FEl3wtch5o';
  late final GooglePlacesService _placesService;
  Timer? _searchDebounce;

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

  Color _getHighestRiskColor() {
    if (_smartDetectedVehicles.isEmpty) return Colors.green;
    
    final highestRisk = _smartDetectedVehicles
        .map((v) => v.collisionMetrics?.riskLevel ?? CollisionRisk.none)
        .reduce((a, b) => a.index > b.index ? a : b);
    
    switch (highestRisk) {
      case CollisionRisk.critical:
        return Colors.red.shade900;
      case CollisionRisk.high:
        return Colors.red;
      case CollisionRisk.medium:
        return Colors.orange.shade700;
      case CollisionRisk.low:
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  IconData _getHighestRiskIcon() {
    if (_smartDetectedVehicles.isEmpty) return Icons.shield;
    
    final highestRisk = _smartDetectedVehicles
        .map((v) => v.collisionMetrics?.riskLevel ?? CollisionRisk.none)
        .reduce((a, b) => a.index > b.index ? a : b);
    
    switch (highestRisk) {
      case CollisionRisk.critical:
        return Icons.dangerous;
      case CollisionRisk.high:
        return Icons.warning;
      case CollisionRisk.medium:
        return Icons.warning_amber;
      case CollisionRisk.low:
        return Icons.info;
      default:
        return Icons.shield;
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

  // Traffic status helper methods
  Color _getWorstTrafficColor() {
    if (_trafficSegments.isEmpty) return Colors.green;
    
    TrafficCongestionLevel worstLevel = TrafficCongestionLevel.free;
    for (final segment in _trafficSegments) {
      if (segment.congestionLevel.index > worstLevel.index) {
        worstLevel = segment.congestionLevel;
      }
    }
    
    switch (worstLevel) {
      case TrafficCongestionLevel.free:
        return Colors.green;
      case TrafficCongestionLevel.light:
        return Colors.yellow.shade700;
      case TrafficCongestionLevel.moderate:
        return Colors.orange;
      case TrafficCongestionLevel.heavy:
        return Colors.red;
      case TrafficCongestionLevel.gridlock:
        return Colors.red.shade900;
    }
  }

  String _getTrafficStatusText() {
    if (_trafficSegments.isEmpty) return 'No traffic data';
    
    final congestionCounts = <TrafficCongestionLevel, int>{};
    
    for (final segment in _trafficSegments) {
      congestionCounts[segment.congestionLevel] = 
          (congestionCounts[segment.congestionLevel] ?? 0) + 1;
    }
    
    // Find the most common congestion level
    TrafficCongestionLevel mostCommon = TrafficCongestionLevel.free;
    int maxCount = 0;
    
    congestionCounts.forEach((level, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = level;
      }
    });
    
    switch (mostCommon) {
      case TrafficCongestionLevel.free:
        return 'Traffic flowing freely';
      case TrafficCongestionLevel.light:
        return 'Light traffic ahead';
      case TrafficCongestionLevel.moderate:
        return 'Moderate congestion';
      case TrafficCongestionLevel.heavy:
        return 'Heavy traffic ahead';
      case TrafficCongestionLevel.gridlock:
        return 'Severe congestion!';
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
    // Initialize Google Places
    _placesService = GooglePlacesService(_googleApiKey);

    // Listen to destination input and fetch suggestions with debounce
    _destinationController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
        final text = _destinationController.text;
        if (text.isEmpty) {
          setState(() => _searchResults = []);
          return;
        }

        try {
          print('Searching for: $text at ${_currentPosition.latitude}, ${_currentPosition.longitude}');
          final preds = await _placesService.autocomplete(
            text,
            lat: _currentPosition.latitude,
            lng: _currentPosition.longitude,
            radius: 50000, // 50km bias
          );

          print('Found ${preds.length} suggestions: ${preds.map((p) => p.description).toList()}');
          
          setState(() {
            _searchResults = preds
                .map((p) => Place(
                      placeId: p.placeId,
                      name: p.description,
                      displayName: p.description,
                      latitude: 0.0,
                      longitude: 0.0,
                    ))
                .toList();
          });
          
          print('_searchResults length: ${_searchResults.length}');
        } catch (e) {
          print('Google Places error: $e');
          setState(() => _searchResults = []);
        }
      });
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _destinationController.dispose();
    _mapController.dispose();
    _proximityService.dispose();
    _smartCollisionService.dispose();
    _trafficService.dispose();
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
    // Direction alerts are now shown in the top bar only
  }

  // Method to create traffic congestion polylines
  List<Polyline> _buildTrafficPolylines() {
    if (_trafficSegments.isEmpty) return [];
    
    return _trafficSegments.map((segment) {
      return Polyline(
        points: segment.segmentPoints,
        color: segment.routeColor,
        strokeWidth: segment.congestionLevel == TrafficCongestionLevel.gridlock ? 8.0 : 6.0,
      );
    }).toList();
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
    } catch (e) {
      setState(() => _isSearching = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location: $e')),
      );
    }
  }

  // When user selects a prediction, fetch place details and set destination
  Future<void> _selectPrediction(Place prediction) async {
    setState(() => _isSearching = true);

    try {
          final detail = await _placesService.getPlaceDetail(prediction.placeId);
      if (detail == null) throw Exception('Failed to get place details');

      final destination = LatLng(detail.lat, detail.lng);
      setState(() {
        _destinationController.text = detail.name;
            _searchResults = [];
        _isSearching = false;
        _destinationPosition = destination;
        _currentDirectionIndex = 0;
      });

      await _updateRoute();
      _fitMapToBounds();
    } catch (e) {
      setState(() => _isSearching = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting place: $e')),
      );
    }
  }

  Future<void> _startNavigation() async {
    if (_destinationPosition == null) return;
    
    setState(() {
      _isNavigationStarted = true;
    });
    
    try {
      // Recenter map to current location
      _mapController.move(_currentPosition, 18);
      _mapController.rotate(_bearing);
      
      // Start Smart Collision Detection
      if (await _checkAndRequestPermissions()) {
        // Start both detection systems
        _proximityService.startScanning(context);
        _smartCollisionService.startSmartDetection(context);
        
        // Listen to old proximity devices
        _proximityService.nearbyVehicles.listen((devices) {
          setState(() {
            _nearbyDevices = devices;
          });
        });
        
        // Listen to smart collision detection
        _smartCollisionService.detectedVehicles.listen((vehicles) {
          setState(() {
            _smartDetectedVehicles = vehicles;
          });
        });
        
        // Start traffic congestion detection if we have route points
        if (_routePoints.isNotEmpty) {
          await _trafficService.startTrafficDetection(_routePoints);
          
          // Listen to traffic updates
          _trafficService.trafficData.listen((segments) {
            setState(() {
              _trafficSegments = segments;
            });
          });
        }
      }
      
      // Start location updates for real-time tracking
      _startLocationUpdates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 8),
                Text('Navigation started! Collision detection active.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isNavigationStarted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting navigation: $e')),
        );
      }
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

  // selection handled by _selectPrediction

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
                        // Autocomplete is handled by the controller listener (debounced)
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
                // START Navigation Button
                if (_destinationPosition != null && !_isNavigationStarted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'START NAVIGATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
                // Navigation Active Status
                if (_isNavigationStarted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Navigation Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Smart Collision Detection Status
                if (_smartDetectedVehicles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getHighestRiskColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getHighestRiskIcon(),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_smartDetectedVehicles.length} vehicle(s) detected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Traffic Congestion Status
                if (_trafficSegments.isNotEmpty && _isNavigationStarted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getWorstTrafficColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.traffic,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTrafficStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Search results dropdown
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var place in _searchResults.take(5)) // Limit to 5 suggestions
                    ListTile(
                      title: Text(place.name),
                      subtitle: Text(place.displayName),
                      onTap: () => _selectPrediction(place),
                      dense: true,
                    ),
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
                        // Smart collision detection markers (high priority)
                        ..._smartDetectedVehicles.where((vehicle) => 
                          vehicle.collisionMetrics != null && 
                          vehicle.collisionMetrics!.riskLevel.index >= 1 // Low risk and above
                        ).map((vehicle) {
                          final angle = Random().nextDouble() * 2 * pi;
                          final lat = _currentPosition.latitude + 
                              (vehicle.distance * cos(angle)) / 111111;
                          final lng = _currentPosition.longitude + 
                              (vehicle.distance * sin(angle)) / (111111 * cos(_currentPosition.latitude * pi / 180));
                          
                          Color markerColor = Colors.yellow;
                          IconData markerIcon = Icons.warning;
                          
                          switch (vehicle.collisionMetrics!.riskLevel) {
                            case CollisionRisk.critical:
                              markerColor = Colors.red.shade900;
                              markerIcon = Icons.dangerous;
                              break;
                            case CollisionRisk.high:
                              markerColor = Colors.red;
                              markerIcon = Icons.warning;
                              break;
                            case CollisionRisk.medium:
                              markerColor = Colors.orange;
                              markerIcon = Icons.warning_amber;
                              break;
                            case CollisionRisk.low:
                              markerColor = Colors.yellow.shade700;
                              markerIcon = Icons.info;
                              break;
                            default:
                              break;
                          }
                          
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                markerIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        }),
                        // Legacy proximity markers (lower priority)
                        ..._nearbyDevices.where((device) => 
                          device.isMoving && device.distance <= 5.0
                        ).map((device) {
                          // Calculate approximate position based on distance and movement
                          final angle = Random().nextDouble() * 2 * pi;
                          final lat = _currentPosition.latitude + 
                              (device.distance * cos(angle)) / 111111;
                          final lng = _currentPosition.longitude + 
                              (device.distance * sin(angle)) / (111111 * cos(_currentPosition.latitude * pi / 180));
                          
                          // Determine risk level based on distance
                          final bool isImmediateRisk = device.distance < 2.0;
                          final String riskLevel = isImmediateRisk 
                              ? 'IMMEDIATE RISK!' 
                              : 'Warning: Vehicle Nearby';
                          
                          return Marker(
                            point: LatLng(lat, lng),
                            width: isImmediateRisk ? 40 : 30, // Larger marker for immediate risk
                            height: isImmediateRisk ? 40 : 30,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$riskLevel\n'
                                      'Distance: ${device.distance.toStringAsFixed(1)}m\n'
                                      'Signal Strength: ${device.rssi} dBm'
                                    ),
                                    backgroundColor: isImmediateRisk 
                                        ? Colors.red 
                                        : Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isImmediateRisk
                                      ? Colors.red.withOpacity(0.9)
                                      : Colors.yellow.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isImmediateRisk ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isImmediateRisk 
                                          ? Colors.red.withOpacity(0.5)
                                          : Colors.yellow.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: isImmediateRisk ? 24 : 20,
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
                          // Base route line
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue.withOpacity(0.5),
                            strokeWidth: 3.0,
                          ),
                          // Traffic congestion segments (on top)
                          ..._buildTrafficPolylines(),
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
                  child: FloatingActionButton(
                    heroTag: 'location',
                    onPressed: () {
                      _mapController.move(_currentPosition, 18); // Recenter to current location
                      _mapController.rotate(_bearing);
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.my_location, color: Colors.white),
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
                // Suggestions dropdown moved above map
              ],
            ),
          ),
        ],
      ),
    );
  }
}