# 📱 Quick Reference - Run on Mobile

## ⚡ Super Quick Version (If Flutter Already Installed)

```bash
# 1. Connect your phone or start emulator
# 2. Run these commands:

cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run

# 3. Done! App is on your phone
```

---

## 🔧 If Flutter NOT Installed

### **What You Need:**
- ❌ Flutter SDK is NOT on your computer
- ✅ You need to install it first

### **Installation Steps:**

1. **Download Flutter**
   ```
   Go to: https://flutter.dev/docs/get-started/install/windows
   Download the ZIP file
   ```

2. **Extract Flutter**
   ```
   Extract to: C:\flutter
   ```

3. **Add to PATH**
   ```
   Windows Key → Type "Environment Variables"
   → "Edit system environment variables"
   → "Environment Variables" button
   → Add PATH variable: C:\flutter\bin
   → Restart computer
   ```

4. **Verify**
   ```bash
   flutter --version
   # Should show version number
   ```

---

## 📱 Connect Your Device

### **Physical Android Phone**
```
1. Settings → About phone
2. Tap "Build number" 7 times
3. Settings → Developer options
4. Enable "USB Debugging"
5. Connect phone with USB cable
6. Tap "Allow" on phone
```

### **Android Emulator**
```
1. Open Android Studio
2. Device Manager → Create device
3. Start emulator
4. Wait for it to load (30-60 seconds)
```

---

## 🚀 Run the App

```bash
# Navigate to project
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX

# Install dependencies
flutter pub get

# Run on your device
flutter run
```

---

## 📋 What Happens

```
Flutter runs → Builds APK → Installs on device → Launches app
    ↓            ↓              ↓                    ↓
  (5 sec)     (10-20 sec)    (5 sec)           App opens!
```

---

## 🎯 Expected Output

```
Building for android...
Running Gradle task 'assembleDebug'...
Built build/app/outputs/apk/debug/app-debug.apk
Installing and launching...
I/flutter (12345): Getting weather for location...
```

Then your phone will show the ORBITRIX app! ✅

---

## ⌨️ During Development

```
r  → Hot reload (fast refresh)
R  → Restart app
q  → Quit
d  → Detach
```

---

## ✅ Verification

After app starts:
- [ ] App appears on phone
- [ ] Location permission dialog shows
- [ ] Tap "Allow"
- [ ] Map displays
- [ ] Shows Bangalore location
- [ ] Can zoom/pan map
- Success! ✅

---

## 🐛 Quick Fixes

| Problem | Solution |
|---------|----------|
| Flutter not found | Install Flutter, add to PATH, restart computer |
| Device not detected | Enable USB Debugging, check USB connection |
| App crashes | Grant location permission |
| API key error | Demo key already configured, should work |
| Maps don't load | Make sure demo key setting is true |

---

## 📞 Common Questions

**Q: Does my phone need internet?**
A: Yes, for maps and APIs to work.

**Q: Can I use WiFi instead of USB?**
A: Yes, but USB is faster for development.

**Q: Do I need to install Android Studio?**
A: Yes, it includes Android SDK and emulator.

**Q: Can I run without a phone?**
A: Yes, use Android emulator instead.

**Q: Will the app stay on my phone?**
A: Yes, until you uninstall it.

---

## 🎉 You're Done!

Once Flutter is installed and device connected:

```bash
flutter run
```

And your app is on your phone! 📱

For detailed guide, see: **RUN_ON_MOBILE.md**
