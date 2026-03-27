# 🛠️ Build Instructions

## Quick Start (5 minutes)

### 1. Clone & Open
```bash
git clone https://github.com/artyomx33/slapmac-native.git
cd slapmac-native/src
open SlapMac.xcodeproj
```

### 2. Generate Sounds
```bash
chmod +x generate_sounds.sh
./generate_sounds.sh
```

### 3. Build in Xcode
1. Select your Mac as target (top bar)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)

That's it! The app will appear in your menu bar. 👋💻

---

## Creating DMG for Distribution

### Step 1: Archive
1. Product → Archive
2. Wait for build
3. Click "Distribute App"
4. Select "Copy App"
5. Save to Desktop

### Step 2: Create DMG
```bash
cd ~/Desktop
mkdir SlapMac-Installer
cp -r SlapMac.app SlapMac-Installer/
ln -s /Applications SlapMac-Installer/Applications

# Create DMG
hdiutil create -volname "SlapMac" -srcfolder SlapMac-Installer -ov -format UDZO SlapMac.dmg
```

### Step 3: Notarize (for Gatekeeper)
```bash
# Sign
codesign --force --deep --sign "Developer ID Application: Your Name" SlapMac.dmg

# Notarize
xcrun notarytool submit SlapMac.dmg --apple-id your@email.com --team-id YOUR_TEAM_ID --wait

# Staple
xcrun stapler staple SlapMac.dmg
```

---

## Running Without Sudo (Advanced)

SlapMac requires root access for the accelerometer. Options:

### Option A: Run with sudo (Quick)
```bash
sudo /Applications/SlapMac.app/Contents/MacOS/SlapMac
```

### Option B: LaunchDaemon (Proper)
1. Create helper tool that runs as root
2. Main app communicates via XPC
3. See `research/` folder for implementation details

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Build failed" | Make sure macOS 14.0+ SDK is selected |
| No sound | Check volume, try different voice pack |
| No motion detection | Must run as sudo, check hardware (M2+ required) |
| "Sandbox denied" | Entitlements file should disable sandbox |

---

## Hardware Requirements

✅ **Works:** M2, M3, M4, M1 Pro, M1 Max  
❌ **Won't work:** M1 base model (2020 Air/Pro)

Check your Mac: Apple Menu → About This Mac
