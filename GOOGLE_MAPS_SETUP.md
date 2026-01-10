# Google Maps Setup Guide (Without Required API Key)

## 📱 Problem Solved!

Your app now supports **Google Maps WITHOUT requiring an API key for development**.

---

## ✅ **Option 1: Use Dummy API Key (Recommended for Development)**

### Step 1: Enable Demo Mode
Edit `lib/config/maps_config.dart`:

```dart
static const bool USE_DEMO_KEY = true;  // ← Set to TRUE
static const bool USE_DEMO_MODE = false;  // ← Keep false
```

### Step 2: What You Get
- ✅ Full Google Maps functionality in debug/emulator builds
- ✅ No API key restrictions
- ✅ Maps work without internet in some cases
- ⚠️ Some advanced features may be limited

### Step 3: Run the App
```bash
flutter pub get
flutter run
```

---

## ✅ **Option 2: Use Real Google Maps API Key (For Production)**

### Step 1: Get Free API Key
1. Go to: https://console.cloud.google.com/
2. Create a new project
3. Enable "Maps SDK for Android"
4. Go to "Credentials" → Create API Key
5. Copy your API key

### Step 2: Update Config File
Edit `lib/config/maps_config.dart`:

```dart
static const bool USE_DEMO_KEY = false;  // ← Set to FALSE
static const String GOOGLE_MAPS_API_KEY = 'YOUR_API_KEY_HERE';  // ← Paste here
```

### Step 3: Add to Android
Edit `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.orbitrx"
        minSdk = 21
        targetSdk = 34

        // Add this:
        manifestPlaceholders["MAPS_API_KEY"] = "YOUR_API_KEY_HERE"
    }
}
```

### Step 4: Update Android Manifest
Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <application ...>
        <!-- Add this meta-data -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${MAPS_API_KEY}" />
    </application>
</manifest>
```

---

## 🎯 **GPS is Now OPTIONAL**

Your app previously REQUIRED GPS/Location permission. Now:

- ✅ **GPS is optional** - app works without it
- ✅ **Default location**: Bangalore, India (12.9716°N, 77.5946°E)
- ✅ **If user grants GPS**: Uses real location
- ✅ **If user denies GPS**: Uses default location, continues to work

### Code Changes Made:
- `GPS_REQUIRED = false` in `MapsConfig`
- Location permission is requested but not required
- App has fallback locations

---

## 🔄 **Migrating from Old Dashboard**

### Old Code (OSM/flutter_map):
```dart
import 'dashboard_screen.dart';  // ← Old OSM version
```

### New Code (Google Maps):
```dart
import 'dashboard_screen_google_maps.dart';  // ← New Google Maps version
```

### Update main.dart:
```dart
import 'dashboard_screen_google_maps.dart';  // Change this line

class V2VSafetyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const DashboardScreenGoogleMaps(),  // Change this line
    );
  }
}
```

---

## 📦 **What Changed in pubspec.yaml**

**Removed:**
- `flutter_map: ^6.0.1` (OSM library)

**Added:**
- `google_maps_flutter: ^2.5.0` (Google Maps SDK)

---

## 🚀 **Run the App**

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on device/emulator
flutter run

# 3. See console output for any issues
```

---

## 🐛 **Troubleshooting**

### Issue: Maps don't load
- **Solution**: Make sure `USE_DEMO_KEY = true` in `MapsConfig`

### Issue: "Maps API key not found"
- **Solution**: 
  - For development: Set `USE_DEMO_KEY = true`
  - For production: Add real API key as shown above

### Issue: "Location permission" dialogs
- **Solution**: This is normal. Users can tap "Deny" and app still works

### Issue: "No maps showing, just grey box"
- **Solution**: 
  - Check internet connection
  - Restart emulator/device
  - Clear Flutter cache: `flutter clean` then `flutter pub get`

---

## 🎨 **Customizing Map Behavior**

Edit `lib/config/maps_config.dart`:

```dart
// Change default location
static const double DEFAULT_LAT = 12.9716;  // ← Your latitude
static const double DEFAULT_LNG = 77.5946;  // ← Your longitude
static const double DEFAULT_ZOOM = 14.0;     // ← Zoom level (1-21)
```

---

## 📝 **Notes**

- Demo keys have usage limits (~25,000 requests/day)
- For production, use a real API key with proper restrictions
- Keep API keys secret - never commit to GitHub!
- Use `local.properties` or environment variables for sensitive keys

---

## ✨ **Next Steps**

1. Choose Option 1 or Option 2 above
2. Update `lib/config/maps_config.dart`
3. Update `main.dart` to use `DashboardScreenGoogleMaps`
4. Run `flutter pub get && flutter run`
5. Test on device/emulator

You're all set! 🎉
