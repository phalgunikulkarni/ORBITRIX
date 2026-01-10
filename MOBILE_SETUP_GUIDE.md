# 📱 Step-by-Step: Run ORBITRIX on Mobile Device

## 📋 Prerequisites Checklist

Before starting, check you have:

- [ ] **Flutter SDK installed** (test with `flutter --version`)
- [ ] **Android Studio installed** (for Android SDK)
- [ ] **Physical phone connected** OR **Android emulator running**
- [ ] **USB Debugging enabled** (if using physical phone)
- [ ] **Project downloaded** at `C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX`

---

## 🚀 IF YOU HAVE EVERYTHING - RUN THIS

```bash
# Copy and paste these commands in PowerShell:

cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

**That's it!** Your app will be on your phone in 30 seconds. ✅

---

## 🔧 IF SOMETHING IS MISSING

### **Missing: Flutter SDK**

**How to check:**
```bash
flutter --version
```

**If you get error:** Install Flutter

1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Download ZIP file
3. Extract to: `C:\flutter`
4. Add to PATH: `C:\flutter\bin`
   - Windows Key → "Environment Variables"
   - Edit system environment variables
   - Add `C:\flutter\bin` to PATH
5. **Restart computer**
6. Test: `flutter --version` in new PowerShell

### **Missing: Physical Phone Connection**

**Setup Physical Android Phone:**

1. Open phone Settings
2. Scroll to "About phone"
3. Find "Build number"
4. Tap "Build number" 7 times (until it says "You are now a developer")
5. Go back to Settings
6. Find "Developer options" (now visible)
7. Tap "Developer options"
8. Enable "USB Debugging" (toggle it ON)
9. Enable "Install via USB" (toggle it ON)
10. Connect phone to computer with USB cable
11. On phone, tap "Allow" when prompted
12. Keep phone connected

**Verify connection:**
```bash
flutter devices
```

Should show your phone listed.

### **Missing: Android Emulator**

**Start Android Emulator:**

1. Open Android Studio
2. Click the phone icon (Device Manager) on the right side
3. Find a device listed (or create one)
4. Click the play button to start the emulator
5. Wait 30-60 seconds for it to fully load
6. You should see Android home screen

**Verify connection:**
```bash
flutter devices
```

Should show emulator listed.

---

## 📱 COMPLETE WALKTHROUGH

### **Step 1: Open PowerShell**

```
Windows Key → Type "PowerShell"
Right-click → "Run as Administrator"
```

### **Step 2: Navigate to Project**

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
```

**Verify you're in right folder:**
```bash
ls lib
```

Should show many .dart files. If not, you're in wrong folder.

### **Step 3: Get Dependencies**

```bash
flutter pub get
```

**Wait for it to complete.** You'll see:
```
Running "flutter pub get" in orbitrx...
Resolving dependencies...
Got dependencies
```

### **Step 4: Check Devices**

```bash
flutter devices
```

**You should see:**
```
1 connected device:

your-phone (mobile) • emulator-5554 • android-x86 • Android 11 (API 30)
```

Or if physical phone:
```
Pixel 4 (mobile) • 2C02345AB8A3 • android-arm64 • Android 12 (API 31)
```

**If NO devices shown:**
- Check USB connection
- Check USB Debugging is ON
- Try unplugging and replugging

### **Step 5: Run the App**

```bash
flutter run
```

**First time takes 30-45 seconds. You'll see:**
```
Building for android...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/apk/debug/app-debug.apk (22.3MB)
Installing and launching...
I/flutter ( 9735): Building widgets...
I/flutter ( 9735): Map loaded
```

Then your phone will show the app! 🎉

### **Step 6: Grant Location Permission**

When app opens:
1. A dialog appears asking "Allow location access?"
2. Tap **"Allow"** (or "Allow while using app")
3. App continues with map showing

**Done!** Your app is running! ✅

---

## ⌨️ While App is Running

```
r     → Hot reload (quick refresh)
R     → Full restart
h     → Help (list all commands)
q     → Quit (stops app)
w     → Toggle widget inspector
o     → Open DevTools in browser
d     → Detach (keeps app running)
```

**Example - Hot Reload:**
```
# Make a code change in your editor
# In PowerShell, press: r
# App automatically updates on your phone!
```

---

## 🐛 If App Crashes

### **Check logs:**
Look at PowerShell output. Usually shows error.

### **Common errors:**

**"Gradle build failed"**
```bash
flutter clean
flutter pub get
flutter run
```

**"No location permission"**
1. Open app again
2. Tap "Allow" this time
3. App will work

**"API key not valid"**
This shouldn't happen - demo key is configured. But if it does:
1. Open `lib/config/maps_config.dart`
2. Check `USE_DEMO_KEY = true`

---

## 🎯 Expected Behavior

### **When You Run:**
```
flutter run
    ↓
Console shows: "Building for android..."
    ↓
Takes 30-45 seconds
    ↓
Console shows: "Installing and launching..."
    ↓
Phone shows ORBITRIX splash screen
    ↓
After 2 seconds, asks location permission
    ↓
You tap "Allow"
    ↓
Map appears showing Bangalore
    ↓
You see blue marker (your location)
    ↓
You can zoom/pan/use the map
    ↓
SUCCESS! ✅
```

---

## 🔄 Development Workflow

### **Edit code → Test on phone:**

```bash
# 1. Make a code change in VS Code
# 2. Save file (Ctrl+S)
# 3. In PowerShell, press: r
# 4. App reloads in 2-5 seconds
# 5. Test your change
```

### **Full restart if needed:**

```bash
# If hot reload doesn't work:
# In PowerShell, press: R
# App fully restarts (10-15 seconds)
```

---

## ✅ Verification

After app loads, check these work:

- [ ] Map displays
- [ ] Location shows on map
- [ ] Can zoom (pinch)
- [ ] Can pan (drag)
- [ ] Compass visible
- [ ] No crashes
- [ ] Logs look normal

If all ✅, everything is working!

---

## 🎓 Pro Tips

1. **Keep phone nearby** - Easier to debug
2. **Keep phone unlocked** - App won't launch if locked
3. **Check console** - Errors are shown in PowerShell
4. **Use hot reload** - Much faster than full restart
5. **Check internet** - Required for maps and APIs

---

## 📊 Typical Development Session

```bash
# Start of day
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter run

# Make some code changes
# Press 'r' to test

# Change again
# Press 'r' to test

# Major change
# Press 'R' for full restart

# Done for now
# Press 'q' to stop
```

---

## 🚀 Ready to Start?

Run these commands RIGHT NOW:

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter pub get
flutter run
```

Watch your phone get the app in 30 seconds! 📱

---

## 📞 If Something Goes Wrong

1. **Read the PowerShell error** - Usually explains what's wrong
2. **Check Prerequisites** - All installed?
3. **Try `flutter clean` then `flutter run`**
4. **Restart phone** - Sometimes helps
5. **Unplug/replug USB** - Connection issues

---

## ✨ You're All Set!

Everything is ready. Just run:

```bash
flutter run
```

Your app will be on your phone in seconds!

**Happy testing!** 🎉
