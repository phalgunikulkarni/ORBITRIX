import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../config/maps_config.dart';

/// Google Maps widget - UI ONLY (Navigation & Display)
/// NO GPS controls, NO location features
/// Used only for displaying map and routes
class GoogleMapsWidget extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onMapTapped;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  
  const GoogleMapsWidget({
    Key? key,
    required this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onMapTapped,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
  }) : super(key: key);

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  late GoogleMapController _mapController;
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    if (MapsConfig.isDemoMode()) {
      // Return a demo map view if in demo mode
      return Container(
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Demo Mode: Map Disabled',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Set USE_DEMO_MODE=false in MapsConfig',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() => _isMapReady = true);
        widget.onMapCreated?.call(controller);
      },
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: MapsConfig.DEFAULT_ZOOM,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
      onTap: widget.onMapTapped,
      // IMPORTANT: NO GPS/Location features - UI ONLY for navigation
      myLocationEnabled: false,           // ❌ NO my location button
      myLocationButtonEnabled: false,     // ❌ NO location tracking
      zoomControlsEnabled: widget.zoomControlsEnabled,
      compassEnabled: widget.compassEnabled,
      mapType: MapType.normal,
    );
  }

  @override
  void dispose() {
    if (_isMapReady) {
      _mapController.dispose();
    }
    super.dispose();
  }
}

/// Helper to convert latlong2 LatLng to google_maps_flutter LatLng
LatLng convertLatLng(latlong.LatLng position) {
  return LatLng(position.latitude, position.longitude);
}

/// Helper to convert google_maps_flutter LatLng to latlong2 LatLng
latlong.LatLng convertFromGoogleLatLng(LatLng position) {
  return latlong.LatLng(position.latitude, position.longitude);
}
