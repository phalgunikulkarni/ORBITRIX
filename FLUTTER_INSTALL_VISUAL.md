# 🚀 FLUTTER INSTALLATION - VISUAL GUIDE

## 📌 YOU ARE HERE

```
Downloaded Flutter ✅
         ↓
Install Flutter ← YOU ARE HERE
         ↓
Add to PATH
         ↓
Restart Computer
         ↓
Verify Installation
         ↓
Run App on Mobile ✅
```

---

## 🎯 4-STEP INSTALLATION

### **STEP 1: Extract Flutter ZIP (2 minutes)**

```
Your Downloads Folder
    ↓
You see: flutter_windows_3.x.x-stable.zip
    ↓
Right-click → Extract All...
    ↓
Location: C:\
    ↓
Result: C:\flutter folder created
         ├─ bin/
         ├─ packages/
         ├─ dev/
         └─ (more folders)
```

**Visual:**
```
C:\ Drive
├─ Program Files
├─ Users
├─ flutter  ← NEW! (extracted here)
├─ Windows
└─ (other folders)
```

---

### **STEP 2: Add Flutter to PATH (2 minutes)**

```
Windows Key
    ↓
Search: "Environment Variables"
    ↓
Click: "Edit the system environment variables"
    ↓
Window opens
    ↓
Click: "Environment Variables..." (bottom-right button)
    ↓
NEW WINDOW opens with two boxes:
    
    Top box: User variables for Lenovo
    ├─ PATH (if exists) ← Click here
    └─ (other variables)
    
    Bottom box: System variables
    ├─ Path ← And also here
    └─ (other variables)

For both PATH/Path:
    Click Edit (or New)
    → Add: C:\flutter\bin
    → Click OK
```

**Important:** Add to BOTH User variables AND System variables!

---

### **STEP 3: Restart Computer (5 minutes)**

```
Click Windows icon (bottom-left)
    ↓
Click Power icon
    ↓
Click "Restart"
    ↓
Computer restarts
    ↓
Windows loads
    ↓
You log in
    ↓
Ready to verify ✓
```

**Why restart?** Windows needs to reload PATH variable.

---

### **STEP 4: Verify Installation (30 seconds)**

```
Open PowerShell (NEW window after restart!)
    ↓
Type: flutter --version
    ↓
Press Enter
    ↓
See version number?
    ↓
YES ✅              NO ❌
    ↓                   ↓
INSTALLED!         Troubleshoot below
    ↓
Run app! 🎉
```

---

## 📊 WHAT SHOULD YOU SEE

### **Success:**
```bash
$ flutter --version
Flutter 3.13.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 08d5e7c4f9
Engine • revision 3bcc5702fa
Tools • Dart 3.1.0
```

✅ This means Flutter is installed!

### **Error:**
```bash
$ flutter --version
flutter : The term 'flutter' is not recognized as the name of a cmdlet, 
function, script file, or operable program.
```

❌ Something didn't work - see troubleshooting below.

---

## 🔍 WHERE TO FIND FILES

### **Flutter ZIP Location:**
```
C:\Users\Lenovo\Downloads\flutter_windows_*.zip
                          ↑
                    Look here first
```

### **After Extraction:**
```
C:\flutter
├─ bin\
│  ├─ flutter (main executable)
│  └─ flutter.bat
├─ packages\
├─ dev\
└─ (more folders)
```

**Check if extraction worked:**
```
1. Open File Explorer
2. Go to C:\ drive
3. You should see a "flutter" folder
4. Double-click it
5. You should see: bin, packages, dev, etc.
```

---

## 🛠️ PATH VARIABLE SETUP - VISUAL

### **Finding Environment Variables:**

```
Method 1: GUI
1. Windows Key (bottom-left) → type "Environment Variables"
2. Click "Edit the system environment variables"
3. A window opens
4. Click "Environment Variables..." button
5. Another window opens → This is what you want!

Method 2: Direct
1. Windows Key
2. Search "Environment Variables"
3. Click the option that appears
```

### **Adding to PATH:**

```
Environment Variables window shows TWO sections:

┌─────────────────────────────────┐
│ User variables for Lenovo       │
├─────────────────────────────────┤
│ NAME          VALUE             │
│ (existing)    (values)          │
│               (...)             │
│                                 │
│ [New...] [Edit...] [Delete...]  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ System variables                │
├─────────────────────────────────┤
│ NAME          VALUE             │
│ Path          C:\Windows;...    │
│ (others)      (values)          │
│                                 │
│ [New...] [Edit...] [Delete...]  │
└─────────────────────────────────┘

WHAT TO DO:
1. In User variables: Click "New..."
   → Variable name: PATH
   → Variable value: C:\flutter\bin
   → OK

2. In System variables: Find "Path", click "Edit..."
   → Click "New"
   → Value: C:\flutter\bin
   → OK

3. Click OK to close the window
```

---

## ⚠️ COMMON MISTAKES

```
WRONG ❌                    CORRECT ✅
─────────────────────────────────────
Extract to Downloads        Extract to C:\
    ↓                          ↓
C:\Users\Lenovo\            C:\flutter
    Downloads\flutter           ├─ bin
    ├─ bin                      ├─ packages
    └─ ...                      └─ dev

─────────────────────────────────────
Don't restart                Restart computer
    ↓                            ↓
flutter command              flutter command
doesn't work                 works ✓

─────────────────────────────────────
Old PowerShell               New PowerShell
    ↓                            ↓
Old PATH                     New PATH
    ↓                            ↓
flutter not found            flutter found
```

---

## 🔧 TROUBLESHOOTING

### **Problem: "flutter not recognized"**

```
Diagnosis:
1. Did you restart? (MUST DO THIS)
   → No? Restart now
   
2. Are you in new PowerShell window?
   → No? Open new window
   
3. Is C:\flutter folder really there?
   → Check File Explorer: C:\ should show "flutter"
   
4. Did you add to PATH?
   → Check Windows Environment Variables
   → Should see C:\flutter\bin in list
```

**Fix:**
```
1. Restart computer (if not done)
2. Open NEW PowerShell
3. Type: flutter --version
4. If still error: Check C:\flutter exists
5. If not: Extract ZIP again to C:\
6. Restart computer again
7. Try flutter --version in NEW PowerShell
```

---

## ✅ VERIFICATION CHECKLIST

After extraction and PATH setup, verify:

```
✓ File Explorer
  → Go to C:\
  → See "flutter" folder? YES ✓

✓ PATH Variable
  → Environment Variables window
  → See C:\flutter\bin in PATH? YES ✓

✓ Restart
  → Computer restarted? YES ✓

✓ PowerShell
  → New PowerShell window? YES ✓
  → flutter --version works? YES ✓
  → Shows version number? YES ✓

ALL ✓ → INSTALLED! 🎉
```

---

## 📋 STEP-BY-STEP CHECKLIST

- [ ] Locate flutter_windows_*.zip in Downloads
- [ ] Right-click and select "Extract All..."
- [ ] Select location: C:\
- [ ] Wait for extraction to complete
- [ ] Open File Explorer and verify C:\flutter exists
- [ ] Windows Key → Search "Environment Variables"
- [ ] Open "Edit the system environment variables"
- [ ] Click "Environment Variables..." button
- [ ] Add C:\flutter\bin to User PATH
- [ ] Add C:\flutter\bin to System PATH
- [ ] Click OK to save
- [ ] Restart computer
- [ ] Open NEW PowerShell window
- [ ] Type: flutter --version
- [ ] See version number? → Installed! ✅

---

## 🚀 NEXT STEPS

Once `flutter --version` works:

```bash
# 1. Check full setup
flutter doctor

# 2. Go to project
cd C:\Users\Lenovo\Documents\Orbitrix\ORBITRIX

# 3. Get dependencies
flutter pub get

# 4. Run on device
flutter run
```

---

## ✨ YOU'RE ALMOST THERE!

```
Installation Progress:
████████████████░░░░░░░░░░░░░░░░░░░░░░ 50%

Step 1: Download ✓ (done)
Step 2: Install ← (you are here)
Step 3: Run app → (next)
```

---

**Follow this guide and Flutter will be installed in 10 minutes!** ⏱️
