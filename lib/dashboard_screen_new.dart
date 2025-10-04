import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  MapController? _mapController;
  LatLng _currentPosition = const LatLng(12.9716, 77.5946); // Default: Bangalore

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Markers for BLE-detected vehicles
  final List<Marker> _markers = [];

  // Status indicators
  bool gpsOn = true;
  bool bluetoothConnected = true;

  Future<void> _checkLocationPermission() async {
    final loc = Location();
    try {
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          setState(() => gpsOn = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => gpsOn = false);
          return;
        }
      }

      setState(() => gpsOn = true);
    } catch (e) {
      setState(() => gpsOn = false);
    }
  }

  Future<void> _getUserLocation() async {
    if (!mounted) return;

    final loc = Location();
    try {
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() => gpsOn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
          return;
        }
      }

      PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (!mounted) return;
          setState(() => gpsOn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
          return;
        }
      }

      final userLocation = await loc.getLocation();
      if (!mounted) return;

      final lat = userLocation.latitude;
      final lon = userLocation.longitude;
      
      if (lat == null || lon == null) {
        throw Exception('Could not get location coordinates');
      }

      setState(() {
        _currentPosition = LatLng(lat, lon);
        gpsOn = true;
      });

      // Move map if controller available
      _mapController?.move(_currentPosition, 15);
      
    } catch (e) {
      if (!mounted) return;
      setState(() => gpsOn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // BLE marker scaffold: convert a discovered device (id, lat/lng) into a marker
  void addBleMarker(String id, LatLng position, {String? label}) {
    final marker = Marker(
      point: position,
      child: Tooltip(
        message: label ?? 'Vehicle $id',
        child: const Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 35,
        ),
      ),
    );
    setState(() => _markers.add(marker));
  }

  // Remove marker
  void removeBleMarker(String id) {
    // Since we don't have marker IDs in flutter_map, we'll need to
    // track markers differently - for now just removing all markers
    setState(() => _markers.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('V2V Safety Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 14,
                    onMapReady: () async {
                      try {
                        await _getUserLocation();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error initializing map: $e')),
                          );
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.orbitrx',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getUserLocation,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Tracking'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mapController?.move(_currentPosition, 16),
                      icon: const Icon(Icons.map),
                      label: const Text('View Map'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}