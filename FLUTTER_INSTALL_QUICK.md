# ✅ FLUTTER INSTALLATION CHECKLIST - QUICK VERSION

## 🎯 3 SIMPLE STEPS

### **Step 1: Extract Flutter** (2 minutes)
```
1. Find: C:\Users\Lenovo\Downloads\flutter_windows_*.zip
2. Right-click → "Extract All..."
3. Extract to: C:\ (so you get C:\flutter)
4. Verify: Open C:\ and you see "flutter" folder ✓
```

### **Step 2: Add to PATH** (2 minutes)
```
1. Windows Key → Type "Environment Variables"
2. Click "Edit the system environment variables"
3. Click "Environment Variables..." button
4. Click "New..." button
5. Variable name: PATH
6. Variable value: C:\flutter\bin
7. Click OK
8. Find "Path" in System variables below
9. Click Edit, click New, add: C:\flutter\bin
10. Click OK, OK, OK
```

### **Step 3: Restart Computer** (5 minutes)
```
1. Save all work
2. Click Windows icon → Power → Restart
3. Wait for restart
4. Log back in
```

### **Step 4: Verify** (30 seconds)
```
1. Open NEW PowerShell window
2. Type: flutter --version
3. Should show version number
4. If yes: ✅ INSTALLED!
5. If no: See troubleshooting below
```

---

## 🐛 IF SOMETHING GOES WRONG

### **"flutter: not recognized"**
```
✗ Did you restart computer? → YES: Continue to troubleshooting
✗ Did you add PATH variable? → YES: Continue to troubleshooting
✗ Using old PowerShell window? → Open NEW window

If still not working:
1. Check C:\flutter folder exists
   → Open File Explorer
   → Go to C:\
   → You should see "flutter" folder
   → If not, extract ZIP again

2. Check PATH variable
   → Windows Key → "Environment Variables"
   → Look for C:\flutter\bin in the list
   → If not there, add it again
   → Restart computer again
```

### **"C:\flutter not found"**
```
1. Extract the ZIP file to C:\ (not Downloads!)
2. After extraction, you should have:
   C:\flutter\bin
   C:\flutter\packages
   C:\flutter\dev
   (and more folders)
3. If not, re-extract the ZIP
```

---

## ✅ VERIFICATION

Run this command to verify:

```bash
flutter --version
```

### **Success Output:**
```
Flutter 3.x.x • channel stable
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart x.x.x
```

### **Error Output:**
```
flutter: The term 'flutter' is not recognized
```
→ Something not done correctly, follow troubleshooting above

---

## 📋 CHECKLIST

- [ ] Downloaded Flutter ZIP
- [ ] Extracted to C:\flutter
- [ ] Can see C:\flutter folder in File Explorer
- [ ] Added C:\flutter\bin to PATH
- [ ] Restarted computer
- [ ] flutter --version works (shows version)

---

## 🚀 AFTER INSTALLATION

```bash
# Check everything is fine
flutter doctor

# Navigate to project
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX

# Get dependencies
flutter pub get

# Run app
flutter run
```

---

## 💡 KEY POINTS

1. **Extract to C:\flutter** - Not Downloads, not Documents, C:\ root
2. **Restart computer** - MUST restart after adding PATH
3. **Use NEW PowerShell** - Open new window after restart
4. **Add to PATH** - Both in User variables AND System variables
5. **Check flutter folder exists** - Before troubleshooting

---

## 📞 QUICK HELP

| Issue | Fix |
|-------|-----|
| "not recognized" | Restart computer, open new PowerShell |
| Path not working | Add to both User AND System PATH variables |
| Can't find folder | Extract ZIP to C:\ root |
| Still doesn't work | Delete C:\flutter, extract again, restart |

---

## ✨ DONE?

If `flutter --version` shows version number → **You're done!** ✅

Next: Run the app on your mobile device! 🎉

See: **MOBILE_COMPLETE_GUIDE.md**
