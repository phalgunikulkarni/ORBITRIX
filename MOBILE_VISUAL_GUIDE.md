# 📱 Running ORBITRIX on Mobile - Visual Guide

## 🎯 The Complete Picture

```
┌─────────────────────────────────────────────────────────┐
│                   ORBITRIX ON MOBILE                     │
│                                                          │
│  Step 1: Install Flutter              (One time)       │
│  ├─ Download from flutter.dev                          │
│  ├─ Extract to C:\flutter                              │
│  └─ Add to Windows PATH                                │
│                                                          │
│  Step 2: Connect Device               (Before running) │
│  ├─ Physical phone: Enable USB Debugging               │
│  └─ Emulator: Start from Android Studio                │
│                                                          │
│  Step 3: Run App                      (Every time)     │
│  ├─ cd project folder                                  │
│  ├─ flutter pub get                                    │
│  └─ flutter run                                        │
│                                                          │
│  Step 4: Grant Permission             (On first run)   │
│  └─ Tap "Allow" on location dialog                     │
│                                                          │
│  Result: App on your phone! ✅                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Checklist Before Running

```
Prerequisites:
☐ Flutter SDK installed (check: flutter --version)
☐ Android Studio installed
☐ Device connected OR emulator running
☐ USB Debugging enabled (if physical phone)
☐ Project at: C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
```

---

## ⚡ 3-COMMAND QUICKSTART

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

**Wait 30-45 seconds... App appears on your phone!** ✨

---

## 🔄 The Process

```
┌──────────────┐
│ flutter run  │
└──────────────┘
       │
       ↓
┌──────────────────────────┐
│ Compile Dart to APK      │  (30-45 seconds)
│ ├─ Build                 │
│ ├─ Compile               │
│ └─ Package               │
└──────────────────────────┘
       │
       ↓
┌──────────────────────────┐
│ Install on Device        │  (5-10 seconds)
│ └─ Push APK to phone     │
└──────────────────────────┘
       │
       ↓
┌──────────────────────────┐
│ Launch App               │  (2-3 seconds)
│ └─ Start ORBITRIX        │
└──────────────────────────┘
       │
       ↓
🎉 App opens on your phone!
```

---

## 📱 Physical Phone Setup

```
Settings
  ├─ About phone
  │   └─ Tap "Build number" 7 times
  │
  └─ Developer options (now visible)
      ├─ Enable "USB Debugging" ✅
      ├─ Enable "Install via USB" ✅
      └─ Connect with USB cable
```

---

## 🖥️ Emulator Setup

```
Android Studio
  ├─ Device Manager (right panel)
  │   ├─ Create device
  │   └─ Select: Pixel 4, API 30+
  │
  └─ Start emulator
      └─ Click play button
```

---

## 📊 What's Required

| Component | Purpose | Status |
|-----------|---------|--------|
| Flutter SDK | Build the app | ❌ Need to install |
| Android Studio | Compile & emulator | ✅ You probably have it |
| Device | Run the app | ✅ You have a phone |
| USB Cable | Connect phone | ✅ You have one |
| Internet | Maps & APIs | ✅ You have it |

---

## 🚀 Running the App

### **Command Line**

```bash
# Option 1: Run on any connected device
flutter run

# Option 2: Run on specific device
flutter devices                    # List devices
flutter run -d <device-id>        # Run on specific one

# Option 3: Release mode (faster, no logs)
flutter run --release
```

### **During Development**

```
Key         Action
───         ──────
r           Hot reload (fast)
R           Full restart
h           Show help
q           Quit
w           Widget inspector
o           Open DevTools
d           Detach
```

---

## ✅ After App Launches

```
1. Splash screen appears (ORBITRIX logo)
   └─ Wait 2-3 seconds

2. Location permission dialog
   └─ Tap "Allow"

3. Map displays showing:
   └─ Bangalore, India as default location
   ├─ Blue marker (your location)
   ├─ Zoom controls
   └─ Compass

4. You can:
   ├─ Zoom (pinch)
   ├─ Pan (drag)
   ├─ Rotate (two-finger twist)
   └─ See nearby vehicles (BLE markers)
```

---

## 🔍 Console Output

### **What You'll See**

```
$ flutter run
Flutter run key commands.
Press 'r' to hot reload, 'R' to hot restart, 'h' for help.

Building for android...
Running Gradle task 'assembleDebug'...
Built build/app/outputs/apk/debug/app-debug.apk
Installing and launching org.example.orbitrx on device...

I/flutter ( 9735): Building widgets...
I/flutter ( 9735): GoogleMap initialized
I/flutter ( 9735): Getting GPS location...
I/flutter ( 9735): Location obtained: 12.9716, 77.5946
I/flutter ( 9735): Map ready
```

✅ App is now running on your phone!

---

## 🐛 Quick Troubleshooting

```
Problem                    → Solution
─────────────────────────────────────────────────────────
flutter: not found         → Install Flutter SDK
Device not found           → USB debug on, check cable
App crashes               → Grant location permission
API key error             → Demo key enabled (should work)
Gradle error              → flutter clean → flutter run
Takes too long            → Normal (30-45 sec first time)
                          → Hot reload (r) is faster later
```

---

## 💡 Quick Tips

1. **First run is slow** - Compiles everything (30-45 sec)
2. **After first run** - Press `r` for hot reload (2-5 sec)
3. **Keep phone nearby** - Easier to debug
4. **Keep phone unlocked** - App won't launch on locked phone
5. **Check internet** - Required for maps and APIs
6. **Check logs** - PowerShell shows all errors

---

## 📖 More Information

For detailed guides, read:
- `RUN_ON_MOBILE.md` - Complete installation guide
- `MOBILE_SETUP_GUIDE.md` - Step-by-step walkthrough
- `MOBILE_QUICK_REFERENCE.md` - Quick reference

---

## 🎯 5-Minute Summary

```
1. Have Flutter? → No? Install it
2. Have device connected? → No? Connect phone/emulator
3. Run: flutter run
4. Wait 45 seconds
5. Tap "Allow" on location dialog
6. Done! App is running ✅
```

---

## 🚀 Start Now!

Open PowerShell and run:

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

**Your app will be on your phone in seconds!** 📱

---

**Questions?** Check the detailed guides above.

**Ready to start?** Run the commands! 🎉
