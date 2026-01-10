import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:intl/intl.dart';

import 'services/bangalore_locations_service.dart';
import 'services/movement_detection_service.dart';
import 'services/nasa_enhanced_weather_service.dart';
import 'services/authentication_service.dart';
import 'services/places_service.dart';
import 'services/osrm_service.dart';
import 'services/marker_service.dart';
import 'widgets/google_maps_widget.dart';
import 'models/place_model.dart';
import 'login_page.dart';

class DashboardScreenGoogleMaps extends StatefulWidget {
  const DashboardScreenGoogleMaps({super.key});

  @override
  State<DashboardScreenGoogleMaps> createState() => _DashboardScreenGoogleMapsState();
}

class _DashboardScreenGoogleMapsState extends State<DashboardScreenGoogleMaps> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(12.9716, 77.5946); // Bangalore default
  LatLng? _destinationPosition;
  double _currentHeading = 0.0; // Track user's heading/direction
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  bool gpsOn = true;
  bool _hasLocationPermission = false;
  bool _isNavigationStarted = false;
  bool _shouldDetectVehicles = false;
  int _detectedVehicleCount = 0;
  List<LatLng> _detectedVehiclePositions = [];
  
  // Weather
  WeatherData? _currentWeather;
  bool _isLoadingWeather = false;
  
  // Search
  TextEditingController _destinationController = TextEditingController();
  List<BangaloreLocation> _searchResults = [];
  bool _showSearchResults = false;
  
  // Services
  late MovementDetectionService _movementDetectionService;
  final NasaEnhancedWeatherService _weatherService = NasaEnhancedWeatherService();
  
  // Navigation tracking
  StreamSubscription<loc.LocationData>? _navigationLocationSubscription;
  
  // Marker icons
  BitmapDescriptor? _arrowMarkerIcon;

  @override
  void initState() {
    super.initState();
    _movementDetectionService = MovementDetectionService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkLocationPermission();
      _startMovementDetection();
      _loadWeather();
      // Pre-load arrow marker icon for navigation
      _arrowMarkerIcon = await MarkerService.getSimpleArrowMarker(color: Colors.green);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _destinationController.dispose();
    _movementDetectionService.stopMonitoring();
    _navigationLocationSubscription?.cancel();
    super.dispose();
  }

  void _startMovementDetection() {
    _movementDetectionService.startMonitoring();
    _movementDetectionService.movementStatusStream.listen((canDetect) {
      setState(() => _shouldDetectVehicles = canDetect);
    });
  }

  Future<void> _checkLocationPermission() async {
    final location = loc.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
      }

      if (permissionGranted == loc.PermissionStatus.granted) {
        setState(() => gpsOn = true);
        _hasLocationPermission = true;
        await _getUserLocation();
      } else {
        setState(() => gpsOn = false);
      }
    } catch (e) {
      print('Location error: $e');
      setState(() => gpsOn = false);
    }
  }

  Future<void> _getUserLocation() async {
    if (!mounted) return;
    final location = loc.Location();
    try {
      final userLocation = await location.getLocation();
      if (userLocation.latitude != null && userLocation.longitude != null) {
        final newPos = LatLng(userLocation.latitude!, userLocation.longitude!);
        setState(() {
          _currentPosition = newPos;
          gpsOn = true;
        });
        
        // Add current location marker
        _addCurrentLocationMarker();
        
        // Center map on user location with proper zoom
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPos,
                zoom: 10.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => gpsOn = false);
    }
  }

  void _addCurrentLocationMarker() {
    final marker = Marker(
      markerId: const MarkerId('current_location'),
      position: _currentPosition,
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    setState(() => _markers.add(marker));
  }

  void _updateCurrentLocationMarkerForNavigation() {
    // During navigation, update marker to show direction with arrow
    final marker = Marker(
      markerId: const MarkerId('current_location'),
      position: _currentPosition,
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: _arrowMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      rotation: _currentHeading, // Rotate based on user's heading/direction
      flat: true, // Flatten the marker so rotation is visible
    );
    
    print('Arrow marker updated - Position: $_currentPosition, Heading: $_currentHeading°');
    
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'current_location');
      _markers.add(marker);
    });
  }

  void _startContinuousLocationTracking() {
    // Start listening to location updates during navigation
    final location = loc.Location();
    try {
      _navigationLocationSubscription = location.onLocationChanged.listen(
        (loc.LocationData newLocation) {
          if (newLocation.latitude != null && newLocation.longitude != null) {
            final newPos = LatLng(newLocation.latitude!, newLocation.longitude!);
            
            setState(() {
              _currentPosition = newPos;
              // Update heading if available
              if (newLocation.heading != null && newLocation.heading! >= 0) {
                _currentHeading = newLocation.heading!;
              }
            });

            // Log location and heading updates
            print('Location update - Lat: ${newLocation.latitude}, Lng: ${newLocation.longitude}, Heading: ${newLocation.heading}°');

            // Update the marker with current position and heading
            _updateCurrentLocationMarkerForNavigation();

            // Keep map centered on user during navigation
            if (_mapController != null && _isNavigationStarted) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: newPos,
                    zoom: 18.0, // Closer zoom during active navigation
                    bearing: _currentHeading, // Rotate map to match user's heading
                  ),
                ),
              );
            }
          }
        },
        onError: (error) {
          print('Navigation location error: $error');
        },
      );
    } catch (e) {
      print('Error starting continuous location tracking: $e');
    }
  }

  void _stopContinuousLocationTracking() {
    // Cancel the location subscription when navigation ends
    _navigationLocationSubscription?.cancel();
    _navigationLocationSubscription = null;
  }

  void _searchLocations(String input) async {
    if (input.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    try {
      // Use Google Places API
      final predictions = await PlacesService.searchPlaces(input);
      
      if (!mounted) return;
      
      setState(() {
        _searchResults = predictions
            .map((p) => BangaloreLocation(
                  name: p.description,
                  description: p.mainText,
                  coordinates: const LatLng(0, 0), // Will be fetched on selection
                ))
            .toList();
        _showSearchResults = _searchResults.isNotEmpty;
      });
      
      print('Found ${predictions.length} places');
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    }
  }

  void _selectDestination(BangaloreLocation location) async {
    setState(() {
      _destinationController.text = location.name;
      _showSearchResults = false;
    });

    // If we need to fetch coordinates from PlacesService, do it here
    // For now, use the location provided
    final coordinates = location.coordinates;
    
    if (coordinates.latitude == 0 && coordinates.longitude == 0) {
      // Try to get coordinates using geocoding
      print('Warning: Location has no coordinates, using geocoding');
      try {
        final locations = await locationFromAddress(location.name);
        if (locations.isNotEmpty) {
          final first = locations.first;
          setState(() {
            _destinationPosition = LatLng(first.latitude, first.longitude);
          });
        }
      } catch (e) {
        print('Geocoding error: $e');
      }
      return;
    }

    setState(() {
      _destinationPosition = coordinates;
    });

    // Add destination marker
    final marker = Marker(
      markerId: const MarkerId('destination'),
      position: coordinates,
      infoWindow: InfoWindow(
        title: location.name,
        snippet: location.description,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(marker);
    });

    // Animate camera to show both markers
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: coordinates,
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoadingWeather = true);
    try {
      // Get current weather based on position
      final weatherData = await _weatherService.getWeatherForLocation(
        Location(latitude: _currentPosition.latitude, longitude: _currentPosition.longitude),
      );
      if (weatherData != null) {
        setState(() {
          _currentWeather = weatherData;
          _isLoadingWeather = false;
        });
      } else {
        setState(() => _isLoadingWeather = false);
      }
    } catch (e) {
      print('Weather error: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthenticationService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _startTracking() async {
    if (_destinationPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Computing route...'),
          ],
        ),
      ),
    );

    try {
      // Get route from OSRM (free, no API key needed)
      final routePoints = await OSRMService.getRoute(
        _currentPosition,
        _destinationPosition!,
      );

      // Get route info (distance, duration)
      final routeInfo = await OSRMService.getRouteDetails(
        _currentPosition,
        _destinationPosition!,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (routePoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not compute route. Try again.')),
        );
        return;
      }

      setState(() => _isNavigationStarted = true);
      
      // Start continuous location tracking during navigation
      _startContinuousLocationTracking();
      
      // Add destination marker
      final destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: _destinationPosition!,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: _destinationController.text,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(destinationMarker);
      });
      
      // Draw route polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      );
      setState(() => _polylines.add(polyline));
      
      // Enable hazard detection during navigation
      setState(() {
        _detectedVehicleCount = 0;
        _detectedVehiclePositions = [];
      });

      // Show route info in snackbar
      if (routeInfo != null) {
        final distanceKm = routeInfo['distance_km'] ?? 0;
        final durationMin = routeInfo['duration_min'] ?? '0';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route: ${distanceKm.toStringAsFixed(2)} km (~$durationMin min) - Hazard detection ACTIVE',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('V2V Safety Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Chip(
                label: Text(
                  gpsOn ? 'GPS: ON' : 'GPS: OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: gpsOn ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Weather Widget
          if (_currentWeather != null && !_isLoadingWeather)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF34495E),
              child: Row(
                children: [
                  Icon(
                    _currentWeather!.temperature > 25
                        ? Icons.wb_sunny
                        : Icons.cloud,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentWeather!.condition,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Wind: ${_currentWeather!.windSpeed.toStringAsFixed(1)} m/s',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Humidity: ${_currentWeather!.humidity.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF34495E),
            child: TextField(
              controller: _destinationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search destination...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                suffixIcon: _destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _destinationController.clear();
                          setState(() {
                            _searchResults = [];
                            _showSearchResults = false;
                            _destinationPosition = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: _searchLocations,
            ),
          ),

          // Search Results
          if (_showSearchResults && _searchResults.isNotEmpty)
            Container(
              color: const Color(0xFF34495E),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    title: Text(
                      location.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      location.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    leading: const Icon(Icons.place, color: Colors.orange),
                    onTap: () => _selectDestination(location),
                  );
                },
              ),
            ),

          // Map
          Expanded(
            child: GoogleMapsWidget(
              initialPosition: _currentPosition,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF34495E),
            child: Row(
              children: [
                Icon(
                  _isNavigationStarted 
                      ? Icons.warning_amber_rounded
                      : (_shouldDetectVehicles ? Icons.directions_car : Icons.directions_walk),
                  color: _isNavigationStarted 
                      ? (_detectedVehicleCount > 0 ? Colors.red : Colors.amber)
                      : (_shouldDetectVehicles ? Colors.green : Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isNavigationStarted
                        ? _detectedVehicleCount > 0
                            ? 'HAZARD DETECTED: $_detectedVehicleCount vehicle(s) nearby'
                            : 'Navigation: Safe - No hazards detected'
                        : (_shouldDetectVehicles
                            ? 'Detection: ACTIVE'
                            : (_movementDetectionService.isIndoor
                                ? 'Inside building'
                                : 'Vehicle stopped')),
                    style: TextStyle(
                      color: _isNavigationStarted 
                          ? (_detectedVehicleCount > 0 ? Colors.red : Colors.amber)
                          : (_shouldDetectVehicles ? Colors.green : Colors.orange),
                      fontWeight: FontWeight.w500,
                      fontSize: _isNavigationStarted ? 13 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
            color: const Color(0xFF2C3E50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startTracking,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isNavigationStarted ? () {
                    // Stop continuous location tracking
                    _stopContinuousLocationTracking();
                    
                    setState(() {
                      _isNavigationStarted = false;
                      _polylines.clear();
                      _detectedVehicleCount = 0;
                      _detectedVehiclePositions.clear();
                      _destinationController.clear();
                      _destinationPosition = null;
                      _markers.removeWhere((m) => m.markerId.value == 'destination');
                      
                      // Restore original blue marker for current location
                      _addCurrentLocationMarker();
                    });
                  } : null,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
