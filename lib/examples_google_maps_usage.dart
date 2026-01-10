/// Example: Using Google Maps in Route Tracking Screen
/// 
/// This file shows how to use the new GoogleMapsWidget in your route tracking
/// and other screens. Copy these patterns for your implementation.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'config/maps_config.dart';
import 'widgets/google_maps_widget.dart';

// Example 1: Simple Map with Markers
class SimpleMapExample extends StatefulWidget {
  const SimpleMapExample({Key? key}) : super(key: key);

  @override
  State<SimpleMapExample> createState() => _SimpleMapExampleState();
}

class _SimpleMapExampleState extends State<SimpleMapExample> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Map')),
      body: GoogleMapsWidget(
        initialPosition: LatLng(
          MapsConfig.DEFAULT_LAT,
          MapsConfig.DEFAULT_LNG,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addMarker() {
    final marker = Marker(
      markerId: MarkerId('marker_${_markers.length}'),
      position: LatLng(
        MapsConfig.DEFAULT_LAT + (0.01 * _markers.length),
        MapsConfig.DEFAULT_LNG,
      ),
      infoWindow: InfoWindow(
        title: 'Marker ${_markers.length + 1}',
      ),
    );
    setState(() => _markers.add(marker));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Example 2: Map with Polyline (Route)
class RouteMapExample extends StatefulWidget {
  const RouteMapExample({Key? key}) : super(key: key);

  @override
  State<RouteMapExample> createState() => _RouteMapExampleState();
}

class _RouteMapExampleState extends State<RouteMapExample> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupRoute();
  }

  void _setupRoute() {
    // Create route markers
    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: LatLng(MapsConfig.DEFAULT_LAT, MapsConfig.DEFAULT_LNG),
      infoWindow: const InfoWindow(title: 'Start'),
    );

    final endMarker = Marker(
      markerId: const MarkerId('end'),
      position: LatLng(MapsConfig.DEFAULT_LAT + 0.05, MapsConfig.DEFAULT_LNG + 0.05),
      infoWindow: const InfoWindow(title: 'Destination'),
    );

    setState(() {
      _markers = {startMarker, endMarker};
    });

    // Create route polyline
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [
        LatLng(MapsConfig.DEFAULT_LAT, MapsConfig.DEFAULT_LNG),
        LatLng(MapsConfig.DEFAULT_LAT + 0.02, MapsConfig.DEFAULT_LNG + 0.02),
        LatLng(MapsConfig.DEFAULT_LAT + 0.04, MapsConfig.DEFAULT_LNG + 0.03),
        LatLng(MapsConfig.DEFAULT_LAT + 0.05, MapsConfig.DEFAULT_LNG + 0.05),
      ],
      color: Colors.blue,
      width: 5,
    );

    setState(() => _polylines.add(polyline));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Map')),
      body: GoogleMapsWidget(
        initialPosition: LatLng(
          MapsConfig.DEFAULT_LAT + 0.025,
          MapsConfig.DEFAULT_LNG + 0.025,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Example 3: Map with Tap Handler (Pick Location)
class LocationPickerExample extends StatefulWidget {
  const LocationPickerExample({Key? key}) : super(key: key);

  @override
  State<LocationPickerExample> createState() => _LocationPickerExampleState();
}

class _LocationPickerExampleState extends State<LocationPickerExample> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMapsWidget(
              initialPosition: LatLng(
                MapsConfig.DEFAULT_LAT,
                MapsConfig.DEFAULT_LNG,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onMapTapped: (latLng) {
                setState(() {
                  _selectedLocation = latLng;
                  _markers = {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: latLng,
                      infoWindow: InfoWindow(
                        title: 'Selected: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
                      ),
                    )
                  };
                });
              },
            ),
          ),
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
                  Text('Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedLocation);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Example 4: Map with Multiple Vehicle Markers
class MultiVehicleMapExample extends StatefulWidget {
  const MultiVehicleMapExample({Key? key}) : super(key: key);

  @override
  State<MultiVehicleMapExample> createState() => _MultiVehicleMapExampleState();
}

class _MultiVehicleMapExampleState extends State<MultiVehicleMapExample> {
  late GoogleMapController _mapController;
  Set<Marker> _vehicleMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadNearbyVehicles();
  }

  void _loadNearbyVehicles() {
    // Simulate loading nearby vehicles
    final vehicles = [
      {'id': 'vehicle_1', 'lat': MapsConfig.DEFAULT_LAT + 0.01, 'lng': MapsConfig.DEFAULT_LNG + 0.01, 'name': 'Car 1'},
      {'id': 'vehicle_2', 'lat': MapsConfig.DEFAULT_LAT - 0.01, 'lng': MapsConfig.DEFAULT_LNG - 0.01, 'name': 'Car 2'},
      {'id': 'vehicle_3', 'lat': MapsConfig.DEFAULT_LAT + 0.02, 'lng': MapsConfig.DEFAULT_LNG - 0.02, 'name': 'Car 3'},
    ];

    final markers = vehicles.map((vehicle) {
      return Marker(
        markerId: MarkerId(vehicle['id']! as String),
        position: LatLng(vehicle['lat']! as double, vehicle['lng']! as double),
        infoWindow: InfoWindow(
          title: vehicle['name']! as String,
          snippet: 'Distance: ~${(0.5 + (vehicle.hashCode % 10) / 10).toStringAsFixed(1)} km',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }).toSet();

    setState(() => _vehicleMarkers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Vehicles')),
      body: GoogleMapsWidget(
        initialPosition: LatLng(
          MapsConfig.DEFAULT_LAT,
          MapsConfig.DEFAULT_LNG,
        ),
        markers: _vehicleMarkers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNearbyVehicles,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
