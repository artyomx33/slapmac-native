# SlapMac

> 👋💻 Slap your MacBook. It screams back.

A native macOS menu bar app that detects when you slap your laptop using the built-in accelerometer, then plays funny sound effects. Volume scales with slap force.

## ⚠️ Requirements

- **macOS 14.0+ (Sonoma)**
- **Apple Silicon Mac** (M2, M3, M4, or M1 Pro/Max)
  - M1 base model (2020) does NOT have the required sensor
- **Must run with elevated privileges** (required for IOKit HID access)

## 🚀 Installation

### Option 1: Download Release
1. Download `SlapMac.dmg` from [Releases](../../releases)
2. Open DMG, drag to Applications
3. **IMPORTANT:** Run with sudo: `sudo /Applications/SlapMac.app/Contents/MacOS/SlapMac`

### Option 2: Build from Source

```bash
git clone https://github.com/artyomx33/slapmac.git
cd slapmac

# Generate sound files
chmod +x generate_sounds.sh
./generate_sounds.sh

# Open in Xcode
open SlapMac.xcodeproj

# Build and run (requires sudo for motion detection)
```

## 🎮 Usage

1. Launch SlapMac (it hides in your menu bar)
2. Slap your MacBook
3. Listen to it scream back!

### Voice Packs

- 😱 **Classic** — "Ouch!", "Hey!", "Stop it!"
- 💋 **Sexy** — "Oh yeah~", "Harder~", "Do it again~"
- 🤬 **Angry** — "HEY!", "STOP!", "IDIOT!"
- 🐐 **Goat** — "BAAAA!", "BLEEEET!"
- 🤖 **Robot** — "ERROR 404", "DAMAGE DETECTED"
- 😵 **Wilhelm** — Classic scream

### Settings

- **Sensitivity:** Adjust slap detection threshold (0.05g - 0.50g)
- **Cooldown:** Prevent spam (100ms - 2000ms)
- **Launch at login:** Always ready to be abused

## 🔧 How It Works

1. **Motion Detection:** Uses IOKit HID to read the Apple SPU (Sensor Processing Unit) accelerometer
2. **Slap Detection:** Calculates g-force magnitude, triggers when above threshold
3. **Audio Playback:** AVAudioPlayer with volume mapped to slap force
4. **Menu Bar:** SwiftUI MenuBarExtra with LSUIElement (no dock icon)

## 🛠️ Technical Details

- **Frameworks:** SwiftUI, IOKit, AVFoundation
- **Architecture:** Apple Silicon only (accesses `AppleSPUHIDDevice`)
- **Sandbox:** Disabled (required for HID access)
- **Distribution:** Direct download (not Mac App Store compatible)

## 📝 License

MIT — Slap freely!

---

Inspired by [slapmac.com](https://slapmac.com) and [spank](https://github.com/taigrr/spank)
