# 📱 How to Run ORBITRIX App on Mobile

## 🔧 STEP 1: Install Flutter SDK

### **Option A: Windows (Recommended)**

1. **Download Flutter**
   - Go to: https://flutter.dev/docs/get-started/install/windows
   - Download the latest Flutter SDK (Windows)

2. **Extract Flutter**
   - Extract the downloaded ZIP file
   - Example location: `C:\flutter`

3. **Add Flutter to PATH**
   - Open Environment Variables:
     - Search "Environment Variables" in Windows
     - Click "Edit the system environment variables"
     - Click "Environment Variables..." button
   - Add Flutter to PATH:
     - Click "New" under "User variables"
     - Variable name: `PATH`
     - Variable value: `C:\flutter\bin`
     - Click OK
   - **RESTART YOUR COMPUTER** (important!)

4. **Verify Installation**
   ```bash
   flutter --version
   ```
   - Should show version number if installed correctly

---

## 📱 STEP 2: Set Up Your Mobile Device

### **Option A: Physical Android Phone**

1. **Enable Developer Mode**
   - Open phone Settings
   - Go to "About phone"
   - Tap "Build number" 7 times
   - You'll see "You are a developer" message

2. **Enable USB Debugging**
   - Go back to Settings
   - Find "Developer options" (now visible)
   - Enable "USB Debugging"
   - Enable "Install via USB"

3. **Connect Phone to PC**
   - Connect phone with USB cable
   - On phone: tap "Allow" when prompted
   - Keep phone connected and unlocked

4. **Verify Connection**
   ```bash
   flutter devices
   ```
   - Should show your phone listed

### **Option B: Android Emulator**

1. **Open Android Studio**
   - Launch Android Studio
   - Click "Device Manager" (right panel)
   - Click "Create device"
   - Select device (e.g., "Pixel 4")
   - Select Android version (API 30+)
   - Click "Finish"

2. **Start Emulator**
   - In Device Manager, click play button next to device
   - Wait for emulator to fully load

3. **Verify Connection**
   ```bash
   flutter devices
   ```
   - Should show emulator listed

---

## 🚀 STEP 3: Run the App

### **From Terminal/PowerShell**

```bash
# Navigate to project directory
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX

# Get dependencies (if not done yet)
flutter pub get

# Run the app
flutter run
```

### **That's It!**
The app will automatically:
- ✅ Install on your device
- ✅ Launch the app
- ✅ Show logs in terminal

---

## 📋 Complete Step-by-Step for Windows + Android Phone

### **Step 1: Install Flutter (One Time)**
```
1. Download from https://flutter.dev/docs/get-started/install/windows
2. Extract to C:\flutter
3. Add C:\flutter\bin to Windows PATH
4. Restart computer
5. Open PowerShell and run: flutter --version
```

### **Step 2: Prepare Your Phone**
```
1. Open Settings → About phone
2. Tap "Build number" 7 times
3. Go back → Developer options
4. Enable "USB Debugging"
5. Connect phone to PC with USB
6. Tap "Allow" on phone when prompted
```

### **Step 3: Run the App**
```bash
# In PowerShell:
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

### **Step 4: Grant Permissions**
- When app launches, grant location permission
- App will start
- You're done! ✅

---

## 🐛 Troubleshooting

### **Problem: "flutter: The term is not recognized"**
**Solution:**
1. Check if Flutter is installed: `C:\flutter` folder exists?
2. Add to PATH (see Step 1 above)
3. RESTART computer (very important!)
4. Try again in new PowerShell window

### **Problem: "No devices found"**
**Solution for Physical Phone:**
1. Check phone USB connection
2. Check USB Debugging is ON
3. Unplug and replug USB
4. Restart phone

**Solution for Emulator:**
1. Open Android Studio
2. Click Device Manager
3. Start the emulator
4. Wait 30-60 seconds for it to fully load
5. Try `flutter devices` again

### **Problem: "App crashes on startup"**
**Solution:**
1. Grant location permission when prompted
2. Check if Google Maps API key is needed
3. Use demo key (already configured)

### **Problem: "API key not valid"**
**Solution:**
1. Demo key is already configured
2. Uses `USE_DEMO_KEY = true` in config
3. Should work without any setup

### **Problem: "Location permission denied"**
**Solution:**
1. This is REQUIRED for this app
2. You must grant location permission
3. Tap "Allow" on permission dialog
4. Rerun if you accidentally denied

---

## ⚡ Quick Commands Reference

```bash
# Check if Flutter is installed
flutter --version

# List connected devices
flutter devices

# Run the app
flutter run

# Run with verbose output (for debugging)
flutter run -v

# Clean and rebuild (if issues)
flutter clean
flutter pub get
flutter run

# Build APK for sharing
flutter build apk

# Run on specific device
flutter run -d <device-id>
```

---

## 🎯 Complete Workflow

### **First Time Setup (15-30 minutes)**
```
1. Download and install Flutter SDK
2. Add to Windows PATH
3. Restart computer
4. Setup Android phone/emulator
5. Connect device
```

### **Running App (Every Time)**
```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get          # Only needed first time or after pubspec changes
flutter run              # Builds and runs on your device
```

### **Stopping App**
- Press `Ctrl + C` in PowerShell
- Or swipe app from recents on phone

### **Rebuilding**
- Press `r` in PowerShell (hot reload)
- Press `R` in PowerShell (full restart)

---

## 📱 What Happens When You Run

```
1. Flutter compiles Dart code
2. Creates APK
3. Installs APK on device
4. Launches app
5. Shows logs in PowerShell
6. App asks for location permission
7. You grant permission
8. App starts showing map
9. Everything works! ✅
```

---

## ✅ Verification Checklist

After setup, verify:
- [ ] Flutter SDK installed (`flutter --version` shows version)
- [ ] Device connected (`flutter devices` shows your phone/emulator)
- [ ] Permissions granted on phone
- [ ] App launches successfully
- [ ] Map displays correctly
- [ ] Location permission dialog appears
- [ ] Grant location permission
- [ ] App fully loads

---

## 🎓 Pro Tips

1. **Keep phone connected** - Faster development
2. **Use hot reload** - Press `r` for quick updates
3. **Check logs** - Terminal shows all errors
4. **Grant permissions** - Required for this app
5. **Use demo key** - Works without API key setup

---

## 🚀 You're Ready!

Once Flutter is installed and your device is ready:

```bash
flutter run
```

That's all you need! The app will be on your phone in seconds.

---

## 📞 Need Help?

- **Flutter not found?** → Reinstall and add to PATH
- **Device not detected?** → Check USB debugging is ON
- **App crashes?** → Grant location permission
- **Maps don't load?** → Demo key should work

Check the terminal output for specific error messages!

---

**Follow these steps and you'll be running the app in minutes!** 🎉
