/// Google Maps Configuration
/// 
/// ⚠️ IMPORTANT NOTES FOR THIS PROJECT:
/// 1. Location permissions are REQUIRED - app cannot work without GPS
/// 2. Google Maps is used ONLY for UI display and navigation
/// 3. NO GPS controls (my location button, location tracking) are enabled
/// 4. All core features (BLE, collision detection, etc) are independent of maps
/// 5. Demo key works for development, switch to real key for production
///
/// To use Google Maps, you have options for the API key:

class MapsConfig {
  // ============================================
  // CONFIGURATION OPTIONS
  // ============================================
  
  /// Set to true for development testing without API key
  static const bool USE_DEMO_KEY = true;
  
  /// Set to true to run app in demo mode (no real maps)
  static const bool USE_DEMO_MODE = false;
  
  /// Hardcoded API key (for testing only - DO NOT commit real keys)
  /// Get a free key: https://console.cloud.google.com/
  static const String GOOGLE_MAPS_API_KEY = 'AIzaSyDummyKeyForTesting123456789';
  
  /// Default location for map initialization (Bangalore, India)
  static const double DEFAULT_LAT = 12.9716;
  static const double DEFAULT_LNG = 77.5946;
  static const double DEFAULT_ZOOM = 10.0; // Road-level view
  
  /// Whether GPS is required for the app
  static const bool GPS_REQUIRED = true; // GPS is REQUIRED for this app
  
  // ============================================
  // RUNTIME CONFIGURATION
  // ============================================
  
  /// Get the actual API key to use
  static String getApiKey() {
    if (USE_DEMO_KEY || USE_DEMO_MODE) {
      return 'AIzaSyDummyKeyForTesting'; // Dummy key for demo mode
    }
    return GOOGLE_MAPS_API_KEY;
  }
  
  /// Check if running in demo mode
  static bool isDemoMode() => USE_DEMO_MODE;
  
  /// Check if using demo API key
  static bool isDemoKey() => USE_DEMO_KEY;
  
  /// Get default starting position
  static Map<String, double> getDefaultPosition() {
    return {
      'latitude': DEFAULT_LAT,
      'longitude': DEFAULT_LNG,
      'zoom': DEFAULT_ZOOM,
    };
  }
}
