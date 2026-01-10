# 📱 RUNNING APP ON MOBILE - COMPLETE GUIDE

## 🎯 TL;DR - Just Want to Run It?

### **If Flutter is Already Installed:**

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

**That's it!** Your app will be on your phone in 45 seconds. ✅

### **If Flutter is NOT Installed:**

1. Download from: https://flutter.dev/docs/get-started/install/windows
2. Extract to: `C:\flutter`
3. Add to Windows PATH: `C:\flutter\bin`
4. Restart computer
5. Then run the commands above

---

## 📋 What You Need

| Item | Status | Note |
|------|--------|------|
| Flutter SDK | ❌ Not on your PC | Need to install |
| Android Studio | ✅ Probably have it | For Android SDK |
| Phone or Emulator | ✅ You have one | Connect or start |
| USB Cable | ✅ You have one | For physical phone |
| Internet | ✅ You have it | For maps/APIs |

---

## 🚀 Complete Process

### **Step 1: Install Flutter (One Time Only)**

**Check if already installed:**
```bash
flutter --version
```

If you see a version number → Skip to Step 2

If error → Install:

1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Download the ZIP file
3. Extract to: `C:\flutter`
4. Add to PATH:
   - Search "Environment Variables" in Windows
   - Add `C:\flutter\bin` to PATH variable
   - **Restart computer**
5. Verify: `flutter --version`

### **Step 2: Prepare Your Device**

#### **Option A: Physical Android Phone**

1. Connect phone with USB cable
2. Open Settings → About phone
3. Tap "Build number" 7 times
4. Go to Developer options
5. Enable "USB Debugging"
6. Enable "Install via USB"
7. On phone: Tap "Allow" when prompted

#### **Option B: Android Emulator**

1. Open Android Studio
2. Click "Device Manager" (right panel)
3. Start a device (or create one)
4. Wait 30-60 seconds for it to fully load

### **Step 3: Run the App**

```bash
# Navigate to project
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX

# Install dependencies
flutter pub get

# Run on your device
flutter run
```

### **Step 4: Grant Permission**

When app opens:
- A dialog asks for location permission
- Tap "Allow" (or "Allow while using app")
- App continues with map showing

**Done!** ✅ Your app is running!

---

## 📱 What Happens When You Run

```
flutter run
    ↓ (5 sec)
Compiling Dart...
    ↓ (10-20 sec)
Building Android project...
    ↓ (5-10 sec)
Installing APK on device...
    ↓ (2-3 sec)
Launching app...
    ↓
ORBITRIX appears on your phone! 🎉
```

**Total time: ~30-45 seconds on first run**

---

## ⌨️ Commands While App is Running

```
r       Hot reload (reload code, keeps state) - ~2-5 sec
R       Full restart (restart app) - ~10-15 sec
h       Show help/commands
q       Quit (stop app)
d       Detach (app keeps running)
```

---

## 🧪 What to Verify

After app loads, check:

```
✅ App appears on phone
✅ Location permission dialog shows
✅ You tap "Allow"
✅ Map displays Bangalore, India
✅ Blue marker shows your location
✅ Can zoom (pinch gesture)
✅ Can pan (drag)
✅ Compass visible
✅ No crashes
✅ Terminal shows no errors
```

If all above ✅ → Everything works perfectly!

---

## 🐛 Troubleshooting

### **Problem: "flutter: not found"**
```
Solution:
1. Install Flutter SDK
2. Add C:\flutter\bin to Windows PATH
3. Restart computer
4. Try again in new PowerShell window
```

### **Problem: "No devices found"**
```
Solution:
If phone:
  1. Enable USB Debugging in Settings
  2. Check USB connection
  3. Unplug/replug USB
  4. Try again

If emulator:
  1. Open Android Studio
  2. Start the emulator
  3. Wait 60 seconds
  4. Try flutter devices again
```

### **Problem: App crashes on launch**
```
Solution:
1. Grant location permission when asked
2. Check that location services are ON on phone
3. Check demo key is enabled: USE_DEMO_KEY = true
```

### **Problem: Takes too long**
```
Normal times:
- First run: 30-45 seconds (building from scratch)
- Hot reload: 2-5 seconds (just reload code)
- Full restart: 10-15 seconds (restart app)
```

---

## 📚 Detailed Guides

For more information, read these files:

1. **MOBILE_QUICK_REFERENCE.md** - Quick lookup
2. **MOBILE_SETUP_GUIDE.md** - Step-by-step guide
3. **MOBILE_VISUAL_GUIDE.md** - Visual flowcharts
4. **RUN_ON_MOBILE.md** - Complete installation

---

## 💡 Pro Tips

1. **First run is slowest** - Takes 30-45 seconds (builds everything)
2. **Use hot reload** - Press `r` after code changes (2-5 sec)
3. **Keep phone connected** - Easier for development
4. **Keep phone unlocked** - App won't launch on locked phone
5. **Check internet** - Required for maps and APIs
6. **Check logs** - PowerShell shows all errors and info

---

## 🎯 Quick Checklist

Before running `flutter run`:

- [ ] Flutter installed (`flutter --version` works)
- [ ] Device connected (phone plugged in OR emulator running)
- [ ] USB Debugging enabled (if physical phone)
- [ ] In correct directory (lib folder visible)
- [ ] Internet working (required for maps)

---

## 🔄 Development Workflow

### **Every Time You Want to Test**

```bash
# Make code changes in VS Code
# Save file (Ctrl+S)
# In PowerShell window with app running:

r              # Hot reload (fast - 2-5 sec)
               # Or full reload if needed:
R              # Full restart (10-15 sec)
```

### **End of Day**

```bash
q              # Quit (stops app)
# App keeps running on phone - manually close if needed
```

---

## 🎓 Learning Path

1. **Quick Start**: Run `flutter run` (3 minutes)
2. **Understand**: Read MOBILE_QUICK_REFERENCE.md (5 minutes)
3. **Deep Dive**: Read MOBILE_SETUP_GUIDE.md (15 minutes)
4. **Troubleshoot**: Check solutions above (as needed)

---

## ✅ Success Criteria

You're done when:
- ✅ `flutter run` completes without errors
- ✅ App appears on your phone
- ✅ Location permission dialog shown
- ✅ Permission granted
- ✅ Map displays
- ✅ No crashes
- ✅ Logs show no errors

---

## 🚀 Ready to Start?

### **Right Now**

Open PowerShell and run:

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

Your app will be on your phone in seconds! 📱

---

## 📞 Need Help?

| Question | Answer |
|----------|--------|
| How do I install Flutter? | See Step 1 above |
| How do I connect my phone? | See Step 2 above |
| How do I run the app? | See Step 3 above |
| Why is it slow? | First run compiles everything (normal) |
| Can I speed it up? | Use hot reload (press `r`) after first run |
| Does my phone need internet? | Yes, for maps and APIs |
| Can I use WiFi? | Yes, but USB is better for dev |
| Will the app stay on my phone? | Yes, until you uninstall |

---

## 🎉 You're All Set!

Everything is ready. The quickest way to get started:

```bash
flutter run
```

That one command will:
1. Build the app
2. Install on your device
3. Launch it
4. Show it on your screen

**In about 45 seconds!** ⚡

---

**Let's go!** 🚀 Your app awaits! 📱
