# 🚀 Flutter Installation Guide - Step by Step

## ✅ You Have Downloaded Flutter - Now Install It!

### **Step 1: Extract Flutter ZIP File**

1. **Find the downloaded ZIP file**
   - Usually in: `C:\Users\Lenovo\Downloads`
   - File name: Something like `flutter_windows_x.x.x-stable.zip`

2. **Extract to C:\flutter**
   - Right-click the ZIP file
   - Select "Extract All..."
   - Extract to location: `C:\` (NOT inside Downloads folder)
   - You should end up with: `C:\flutter` folder
   - Inside you'll see: `bin`, `packages`, `dev`, etc.

**Verify extraction:**
```bash
# Check if flutter folder exists
dir C:\flutter

# Should show many folders and files
```

---

## ✅ Step 2: Add Flutter to Windows PATH

This is VERY IMPORTANT - it lets you run `flutter` command from anywhere.

### **Method 1: GUI (Easier)**

1. **Open Environment Variables**
   - Windows Key (bottom-left of keyboard)
   - Type: `Environment Variables`
   - Click: "Edit the system environment variables"

2. **Find Environment Variables Button**
   - A window opens
   - Click the button: "Environment Variables..." (bottom-right)

3. **Add New PATH Variable**
   - In the "User variables for Lenovo" section
   - Click "New..."
   - Variable name: `PATH`
   - Variable value: `C:\flutter\bin`
   - Click "OK"

4. **Add to System PATH (Important)**
   - In the "System variables" section below
   - Find "Path" (if exists)
   - Click "Edit..."
   - Click "New"
   - Add: `C:\flutter\bin`
   - Click "OK"

5. **Click OK to save all**

### **Method 2: Command Line (Advanced)**

Skip this if you did Method 1.

```bash
# Open PowerShell as Administrator
# Run this command:
$env:Path += ";C:\flutter\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
```

---

## ✅ Step 3: RESTART YOUR COMPUTER

**THIS IS VERY IMPORTANT!** 

Windows needs to reload the PATH variable. Without restart, `flutter` command won't work.

```
1. Save all work
2. Click Windows Key → Power → Restart
3. Wait for computer to restart
4. Log back in
```

---

## ✅ Step 4: Verify Installation

After restart, open a NEW PowerShell window and run:

```bash
flutter --version
```

### **Expected Output:**
```
Flutter X.X.X • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart X.X.X
```

✅ If you see version number, Flutter is installed correctly!

❌ If you get "flutter: not recognized", something went wrong - see Troubleshooting below.

---

## 🔍 Detailed Verification Steps

### **Step 1: Check Flutter Path**
```bash
flutter doctor
```

This shows:
- ✅ or ❌ for Flutter SDK
- ✅ or ❌ for Android Studio
- ✅ or ❌ for Android toolchain
- ✅ or ❌ for Connected devices

### **Step 2: Check Specific Path**
```bash
where flutter
# Should show: C:\flutter\bin\flutter.bat
```

### **Step 3: Check Dart**
```bash
dart --version
# Should show Dart SDK version
```

---

## 🐛 Troubleshooting Installation

### **Problem: "flutter: The term is not recognized"**

**Cause:** PATH not set correctly or computer not restarted.

**Solution:**
```
1. Did you restart computer? (REQUIRED!)
   → If NO: Restart now

2. Did you add C:\flutter\bin to PATH?
   → If NO: Follow Step 2 above
   
3. Try in NEW PowerShell window
   → Old window has old PATH
   
4. Check if C:\flutter folder exists
   → dir C:\flutter
   → If folder doesn't exist, extract ZIP again
```

### **Problem: "flutter doctor" shows ❌ for Android**

**Don't worry!** This is fine for now. You can still run the app.

**Solution:**
- Install Android Studio (if you want to use emulator)
- Or just use physical phone with USB

### **Problem: "Gradle build failed"**

**Cause:** Android SDK not installed.

**Solution:**
```bash
flutter doctor --android-licenses
# Accept all licenses by typing: y
```

### **Problem: "Path is not set"**

**Check:**
```bash
echo $env:Path
# Should show: ...C:\flutter\bin...
```

If not shown, redo Step 2 and restart computer.

---

## ✅ After Installation

Once `flutter --version` works:

1. **Run Flutter Doctor**
   ```bash
   flutter doctor
   ```
   Check what's missing (if anything)

2. **Navigate to Project**
   ```bash
   cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
   ```

3. **Get Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📝 Checklist

- [ ] Downloaded Flutter ZIP
- [ ] Extracted to `C:\flutter`
- [ ] Verified `C:\flutter\bin` exists
- [ ] Added `C:\flutter\bin` to Windows PATH
- [ ] Restarted computer
- [ ] Opened NEW PowerShell
- [ ] Ran `flutter --version` successfully
- [ ] Ran `flutter doctor` to check setup

---

## 🎯 Final Verification

Run this command and you should see Flutter information:

```bash
flutter --version
```

If successful, you're ready to run the app!

```bash
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
flutter run
```

---

## 💡 Important Notes

1. **Must restart computer** - PATH changes don't take effect without restart
2. **Must use NEW PowerShell** - Old windows have old PATH
3. **C:\flutter path** - Must extract to exactly this location (or adjust PATH accordingly)
4. **No spaces in path** - Flutter path should not have spaces
5. **Admin rights** - May need admin to add PATH variable

---

## 🚀 Ready to Continue?

After Flutter installation:

1. **Check it works:**
   ```bash
   flutter --version
   ```

2. **Prepare device:**
   - Physical phone: Enable USB Debugging
   - OR Emulator: Start Android Studio emulator

3. **Run the app:**
   ```bash
   cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX
   flutter pub get
   flutter run
   ```

---

## 📞 Need Help?

**Issue: Can't find the installation file?**
- Check Downloads folder
- Check your Downloads folder in File Explorer
- If not there, download again from https://flutter.dev

**Issue: Don't know if extraction worked?**
```bash
dir C:\flutter
# Should show: bin, packages, dev, etc.
```

**Issue: Still getting "not recognized" error?**
1. Did you restart? (REQUIRED!)
2. Did you add to PATH? (Both User and System)
3. Check if `C:\flutter\bin` is really in PATH:
   ```bash
   echo $env:Path
   ```

---

## ✨ Installation Complete!

Once you see version number from `flutter --version`, you're done!

Next: Run the app on your device! 🎉
