# 🛠️ Step-by-Step Build Guide

## Prerequisites
- macOS 14.0+ (Sonoma)
- Apple Silicon Mac (M2/M3/M4 or M1 Pro/Max)
- ~15GB free space (for Xcode)

---

## Step 1: Install Xcode (One-time, 30 min)

### Option A: Mac App Store (Easiest)
1. Open App Store
2. Search "Xcode"
3. Click Get → Install
4. Wait... (it's 12GB) ☕

### Option B: Apple Developer (Faster download)
1. Go to https://developer.apple.com/download/all/
2. Sign in with Apple ID
3. Download "Xcode 15" .xip file
4. Double-click to extract
5. Drag Xcode to Applications

### Verify Installation
```bash
xcode-select --install  # Install command line tools
xcodebuild -version     # Should show version
```

---

## Step 2: Get SlapMac Source

```bash
# In Terminal
cd ~/Downloads  # or wherever
git clone https://github.com/artyomx33/slapmac-native.git
cd slapmac-native/src
```

---

## Step 3: Generate Sound Files

```bash
chmod +x generate_sounds.sh
./generate_sounds.sh
```

You should see:
```
🎙️  Generating SlapMac voice packs...
😱 Classic pack...
💋 Sexy pack...
🤬 Angry pack...
🐐 Goat pack...
🤖 Robot pack...
😵 Wilhelm pack...
🔄 Converting AIFF to WAV...
✅ Voice packs generated!
```

---

## Step 4: Open in Xcode

```bash
open SlapMac.xcodeproj
```

Or double-click `SlapMac.xcodeproj` in Finder.

---

## Step 5: Build & Run

### In Xcode:

1. **Select Target** (top middle bar)
   - Click "SlapMac" dropdown
   - Choose "My Mac"

2. **Build** (Cmd+B)
   - Should say "Build Succeeded" 🎉
   - If errors → screenshot them, DM me

3. **Run** (Cmd+R)
   - App launches (no window appears — it's menu bar only!)
   - Look for 👋 icon in your menu bar

4. **Test**
   - Slap your MacBook
   - Listen for screams! 🔊

---

## Step 6: Create Release Build

### Archive for Distribution

1. **Product → Archive**
   - Wait for build
   - Organizer window opens

2. **Distribute App**
   - Click "Distribute App"
   - Select "Copy App"
   - Choose Desktop
   - Click Export

You now have `SlapMac.app` on Desktop!

---

## Step 7: Create DMG

```bash
cd ~/Desktop

# Create installer folder
mkdir SlapMac-Installer
cp -r SlapMac.app SlapMac-Installer/

# Add Applications shortcut
ln -s /Applications SlapMac-Installer/Applications

# Create DMG
hdiutil create -volname "SlapMac" -srcfolder SlapMac-Installer -ov -format UDZO SlapMac.dmg

# Clean up
rm -rf SlapMac-Installer
```

**Result:** `SlapMac.dmg` on Desktop! 🎉

---

## Step 8: Test DMG

1. Double-click `SlapMac.dmg`
2. Drag `SlapMac.app` to Applications folder
3. Eject DMG
4. Launch from Applications
5. **Important:** Run with sudo:
   ```bash
   sudo /Applications/SlapMac.app/Contents/MacOS/SlapMac
   ```

---

## Troubleshooting

### "Build Failed" Errors

**Error: No such module 'SwiftUI'**
- Xcode too old → Update to 15.0+

**Error: Cannot find Info.plist**
- File not in right place → Check files are in `SlapMac/` folder

**Error: Signing issues**
- Team not set → Xcode → Signing & Capabilities → Add Apple ID

### Runtime Issues

**No menu bar icon**
- Check menu bar isn't full (too many icons)
- Look for 👋

**No sound**
- Check system volume
- Try different voice pack
- Sounds didn't generate → re-run `generate_sounds.sh`

**No motion detection**
- Must run with `sudo`
- Check hardware: Apple Menu → About This Mac → M2/M3/M4?

---

## 🚀 Share It!

Once DMG works:
1. Upload DMG to Google Drive / Dropbox
2. Share link
3. Or create GitHub Release:
   - Go to https://github.com/artyomx33/slapmac-native/releases
   - Click "Draft new release"
   - Upload DMG
   - Publish! 🎉

---

## Need Help?

**Screenshot any error** and DM me — I'll debug! 🦞
