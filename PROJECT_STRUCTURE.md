# 📊 ORBITRIX Project Structure & What Changed

## 🎯 Overview

Your ORBITRIX app is a **V2V (Vehicle-to-Vehicle) Safety Alert System** that detects hazards using:
- Bluetooth Low Energy (BLE) for nearby vehicles
- Accelerometer/Gyroscope for pothole/brake detection  
- Google Maps for visualization
- NASA weather data for route safety
- Traffic ML predictions

---

## 📁 Project Structure

```
ORBITRIX/
├── lib/
│   ├── main.dart                           ← Entry point
│   │
│   ├── 🆕 config/
│   │   └── maps_config.dart               ← Maps configuration (NEW)
│   │
│   ├── 🆕 widgets/
│   │   └── google_maps_widget.dart        ← Google Maps component (NEW)
│   │
│   ├── Dashboard Screens
│   │   ├── dashboard_screen.dart          ← OLD: OSM version
│   │   ├── 🆕 dashboard_screen_google_maps.dart ← NEW: Google Maps version
│   │   └── dashboard_screen_new.dart      ← Alternate version
│   │
│   ├── Route Tracking
│   │   ├── route_tracking_screen.dart     ← Main tracking screen
│   │   └── route_tracking_screen_additions.dart
│   │
│   ├── 🆕 setup_validator.dart            ← Validation script (NEW)
│   ├── 🆕 examples_google_maps_usage.dart ← Code examples (NEW)
│   │
│   ├── Models
│   │   ├── place.dart
│   │   └── place_model.dart
│   │
│   ├── Services
│   │   ├── google_places_service.dart
│   │   ├── nasa_enhanced_weather_service.dart
│   │   ├── proximity_alert_service.dart
│   │   ├── smart_collision_detection_service.dart
│   │   └── traffic_congestion_detection_service.dart
│   │
│   ├── Theme & UI
│   │   ├── bluetooth_helper.dart
│   │   ├── login_page.dart
│   │   ├── signup_page.dart
│   │   ├── splash_screen.dart
│   │   ├── vehicle_info_page.dart
│   │   └── widgets/ (theme, modern_widgets, weather_widget)
│   │
│   └── Platform
│       └── platform_bluetooth.dart
│
├── android/                                ← Android build config
├── ios/                                    ← iOS build config
├── test/                                   ← Unit tests
├── web/                                    ← Web build config
│
├── pubspec.yaml                           ← Dependencies (UPDATED)
├── analysis_options.yaml                  ← Linting rules
│
├── 📖 README.md                           ← Project overview
├── 📖 NASA_API_SETUP.md                   ← NASA API guide
├── 📖 README_MAPS.md                      ← Maps setup (OLD)
│
├── 🆕 SETUP_COMPLETE.md                   ← MAIN GUIDE (READ THIS!)
├── 🆕 GOOGLE_MAPS_SETUP.md                ← Detailed setup
└── 🆕 GOOGLE_MAPS_MIGRATION.md            ← Migration summary
```

---

## 🔄 What Changed?

### ❌ **Removed**
- `flutter_map: ^6.0.1` - OSM library (not needed)
- GPS as mandatory requirement

### ✅ **Added**
- `google_maps_flutter: ^2.5.0` - Native Google Maps
- `lib/config/maps_config.dart` - Configuration system
- `lib/widgets/google_maps_widget.dart` - Reusable maps component
- `lib/dashboard_screen_google_maps.dart` - New dashboard
- `lib/setup_validator.dart` - Validation helper
- `lib/examples_google_maps_usage.dart` - Code examples
- Documentation files

### 🔧 **Modified**
- `pubspec.yaml` - Updated dependencies
- Maps implementation - Now using Google Maps

---

## 📖 Documentation Files Created

### **1. SETUP_COMPLETE.md** ⭐ START HERE
- Overview of changes
- Quick start guide
- Configuration options
- Next steps

### **2. GOOGLE_MAPS_SETUP.md**
- Detailed setup instructions
- API key options
- Android manifest configuration
- Troubleshooting guide

### **3. GOOGLE_MAPS_MIGRATION.md**
- Summary of changes
- Migration guide
- FAQ

### **4. lib/examples_google_maps_usage.dart**
- Code examples
- Simple map example
- Route with polylines
- Location picker
- Multiple vehicles

---

## 🎯 Key Components

### **Configuration: `lib/config/maps_config.dart`**
```dart
USE_DEMO_KEY = true;           // Use demo key (no API needed)
USE_DEMO_MODE = false;         // Disable maps entirely (for testing)
GOOGLE_MAPS_API_KEY = '...';   // Your API key (if needed)
GPS_REQUIRED = false;          // GPS is optional
DEFAULT_LAT = 12.9716;         // Default location (Bangalore)
DEFAULT_LNG = 77.5946;
DEFAULT_ZOOM = 14.0;
```

### **Maps Widget: `lib/widgets/google_maps_widget.dart`**
Reusable Google Maps component with:
- Marker management
- Polyline support
- Tap handling
- My Location button
- Zoom controls
- Demo mode support

### **Dashboard: `lib/dashboard_screen_google_maps.dart`**
New dashboard with:
- Google Maps instead of OSM
- Optional GPS
- BLE marker management
- Location fallback
- Status indicators

---

## 🚀 How to Use

### **Step 1: Update main.dart**
```dart
// Change this:
import 'dashboard_screen.dart';

// To this:
import 'dashboard_screen_google_maps.dart';

// Then in build():
home: const DashboardScreenGoogleMaps(),
```

### **Step 2: Install dependencies**
```bash
flutter pub get
```

### **Step 3: Run the app**
```bash
flutter run
```

---

## 🗂️ File Dependencies

```
main.dart
├── splash_screen.dart
│   └── dashboard_screen_google_maps.dart (NEW!)
│       ├── config/maps_config.dart
│       ├── widgets/google_maps_widget.dart
│       └── route_tracking_screen.dart
│           ├── services/
│           │   ├── google_places_service.dart
│           │   ├── nasa_enhanced_weather_service.dart
│           │   └── [other services]
│           └── models/place_model.dart
│
└── Old path (still works):
    └── dashboard_screen.dart (uses flutter_map)
```

---

## 🔑 Configuration Decision Tree

```
┌─────────────────────────────────────┐
│  Do you need API key now?          │
└────────────────┬────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
       NO                YES
        │                 │
    [SET]            [DO THIS]
    USE_DEMO_KEY     1. Get API key from
    = true              Google Cloud Console
        │            2. Set USE_DEMO_KEY = false
        │            3. Set GOOGLE_MAPS_API_KEY = '...'
        │            4. Add to AndroidManifest.xml
        │
        └─────────────┬────────────────┘
                      │
              ┌───────▼──────────┐
              │  Run the app     │
              │  flutter run     │
              └──────────────────┘
```

---

## 📋 File Guide

### **To Use Google Maps:**
- `lib/dashboard_screen_google_maps.dart` ← Use this
- `lib/config/maps_config.dart` ← Configure this

### **To Use Old OSM Maps:**
- `lib/dashboard_screen.dart` ← Old version (still available)
- Uses `flutter_map` package

### **To See Examples:**
- `lib/examples_google_maps_usage.dart` ← Code patterns
- Shows 4 different use cases

### **To Validate Setup:**
- `lib/setup_validator.dart` ← Call validateSetup()

---

## ✨ Features by Screen

### **Dashboard Screen (Google Maps)**
- ✅ Live Google Map
- ✅ Vehicle markers (BLE)
- ✅ Current location marker
- ✅ Optional GPS
- ✅ Start tracking button
- ✅ Location fallback
- ✅ Status indicators

### **Route Tracking Screen**
- ✅ Real-time navigation
- ✅ Hazard detection
- ✅ Weather overlay
- ✅ Traffic prediction
- ✅ Google Places search
- ✅ Turn-by-turn directions

### **Other Screens**
- Login/Sign Up
- Vehicle Info
- Bluetooth Management
- Splash Screen

---

## 🔗 Dependencies

### **Maps**
- `google_maps_flutter: ^2.5.0` ← NEW
- (removed `flutter_map`)

### **Location**
- `location: ^5.0.3` ← Optional now
- `geolocator: ^9.0.2` ← For GPS features

### **Search & Places**
- `google_maps_webservice2: ^1.0.5`
- `geocoding: ^2.1.1`

### **Communication**
- `flutter_blue_plus: ^1.31.8` ← BLE
- `http: ^1.1.0` ← API calls

### **Other**
- `permission_handler: ^11.1.0`
- `intl: ^0.18.1`
- `latlong2: ^0.9.0`

---

## 🎓 Learning Path

1. **Start Here**: Read `SETUP_COMPLETE.md`
2. **Configure**: Edit `lib/config/maps_config.dart`
3. **Update**: Change imports in `main.dart`
4. **Learn**: Look at `examples_google_maps_usage.dart`
5. **Run**: `flutter pub get && flutter run`
6. **Integrate**: Use patterns in your screens

---

## ❓ Quick Q&A

**Q: Where do I add my API key?**
A: `lib/config/maps_config.dart` - line with `GOOGLE_MAPS_API_KEY`

**Q: Do I need an API key to run now?**
A: No! Demo mode uses a dummy key that works.

**Q: Can I still use OSM?**
A: Yes! `lib/dashboard_screen.dart` still uses flutter_map

**Q: Is GPS required?**
A: No! GPS is optional. App uses default location as fallback.

**Q: How do I upgrade to real API key?**
A: Change `USE_DEMO_KEY = false` and add your key. That's it!

---

## 📞 Support

- **Setup Issues**: Check `GOOGLE_MAPS_SETUP.md`
- **API Key Issues**: Check `NASA_API_SETUP.md`
- **Code Examples**: See `lib/examples_google_maps_usage.dart`
- **Configuration**: Edit `lib/config/maps_config.dart`

---

## ✅ You're All Set!

Everything is configured and ready. Just:

1. Run `flutter pub get`
2. Update your imports
3. Run `flutter run`

Enjoy your new Google Maps integration! 🎉
