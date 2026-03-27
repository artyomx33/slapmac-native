# SlapMac Native — Build Plan

**Project:** Native macOS menu bar app that detects laptop slaps and screams back  
**Goal:** Replicate web app functionality as native Mac app with real accelerometer support  
**Tech Stack:** Swift, SwiftUI, IOKit HID, AVFoundation  
**Estimated Time:** 2-3 hours  

---

## 📋 Project Overview

Based on research from 3 parallel scouts, here's the complete build plan:

### Key Research Findings:

1. **Menu Bar Apps:** `MenuBarExtra` scene + `LSUIElement` plist setting hides dock icon
2. **Motion Sensor:** Apple Silicon Macs have Bosch BMI286 IMU → access via IOKit HID (undocumented but working)
3. **Audio:** AVAudioPlayer for pre-recorded clips, volume maps to slap force (0.05-0.50g → 0.3-1.0 volume)
4. **Prior Art:** GitHub `taigrr/spank` already implements this on Apple Silicon

---

## 🏗️ Architecture

```
SlapMac/
├── SlapMacApp.swift           # App entry, MenuBarExtra setup
├── MotionDetector.swift       # IOKit HID accelerometer access
├── AudioEngine.swift          # AVAudioPlayer + volume control
├── VoicePackManager.swift     # Sound file management
├── SlapCounter.swift          # Persistence (UserDefaults)
├── SettingsView.swift         # SwiftUI preferences
└── Resources/
    ├── Sounds/
    │   ├── classic/           # Ouch, Hey, Stop it
    │   ├── sexy/              # Oh yeah, Do it again
    │   ├── angry/             # HEY!, STOP!
    │   ├── goat/              # BAAAA!
    │   ├── robot/             # ERROR 404
    │   └── wilhelm/           # AAAAAaaaaahhh!
    └── Assets.xcassets/
```

---

## 📱 Features

### Core (MVP)
- [ ] Menu bar icon (hand.raised.fill)
- [ ] Slap detection via accelerometer
- [ ] 6 voice packs (classic, sexy, angry, goat, robot, wilhelm)
- [ ] Volume scales with slap force
- [ ] Slap counter in menu bar
- [ ] Cooldown timer (prevent spam)

### Settings
- [ ] Sensitivity slider (0.05g - 0.50g)
- [ ] Voice pack selector
- [ ] Cooldown duration
- [ ] Launch at login
- [ ] Quit button

### Advanced (v2)
- [ ] Custom sound packs (user imports)
- [ ] Pitch modulation based on force
- [ ] Combo multipliers
- [ ] Screen flash on hard slaps

---

## 🔧 Technical Implementation

### 1. Menu Bar Setup (MenuBarExtra)
```swift
@main
struct SlapMacApp: App {
    var body: some Scene {
        MenuBarExtra("SlapMac", systemImage: "hand.raised.fill") {
            ContentView()
                .frame(width: 320, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Info.plist additions:**
- `LSUIElement`: true (hide dock icon)
- `NSSupportsSuddenTermination`: false (keep running)

### 2. Motion Detection (IOKit HID)

**Apple Silicon Approach (M2+):**
```swift
import IOKit.hid

class MotionDetector: ObservableObject {
    private var manager: IOHIDManager?
    private let callback: (Double) -> Void
    
    func startMonitoring() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        
        // Match Apple SPU HID device
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: 0x05ac,
            kIOHIDDeviceUsagePageKey: 0xFF00,
            kIOHIDDeviceUsageKey: 3  // Accelerometer
        ]
        
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        IOHIDManagerRegisterInputValueCallback(manager, { ... }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
        IOHIDManagerOpen(manager, 0)
    }
    
    // Parse 22-byte HID report
    // X, Y, Z at offsets 6, 10, 14 (int32 little-endian)
    // Divide by 65536 to get g-force
}
```

**Detection Algorithm:**
```swift
func detectSlap(x: Float, y: Float, z: Float) -> Bool {
    let magnitude = sqrt(x*x + y*y + z*z)
    let threshold = settings.sensitivity  // 0.05 - 0.50
    
    // Cooldown check
    let now = Date()
    guard now.timeIntervalSince(lastSlap) > settings.cooldown else { return false }
    
    if magnitude > threshold {
        lastSlap = now
        return true
    }
    return false
}
```

### 3. Audio Engine (AVAudioPlayer)

```swift
import AVFoundation

class AudioEngine: ObservableObject {
    private var player: AVAudioPlayer?
    private var voicePack = "classic"
    
    func playReaction(force: Double) {
        // Select random sound from pack
        let sounds = voicePacks[voicePack]!
        let sound = sounds.randomElement()!
        
        guard let url = Bundle.main.url(forResource: sound, withExtension: "wav") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            
            // Map force (0.05-0.50) to volume (0.3-1.0)
            let normalized = (force - 0.05) / 0.45
            let volume = 0.3 + (normalized * 0.7)
            player?.volume = Float(min(1.0, max(0.3, volume)))
            
            player?.play()
        } catch {
            print("Audio error: \(error)")
        }
    }
}
```

### 4. Slap Counter (UserDefaults)

```swift
class SlapCounter: ObservableObject {
    @Published var count: Int {
        didSet { UserDefaults.standard.set(count, forKey: "slapCount") }
    }
    
    init() {
        count = UserDefaults.standard.integer(forKey: "slapCount")
    }
    
    func increment() {
        count += 1
    }
}
```

### 5. SwiftUI Settings View

```swift
struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var counter = SlapCounter()
    
    var body: some View {
        VStack(spacing: 20) {
            // Slap counter display
            VStack {
                Text("\(counter.count)")
                    .font(.system(size: 60, weight: .bold))
                Text("Lifetime Slaps")
                    .foregroundColor(.secondary)
            }
            
            // Voice pack picker
            Picker("Voice Pack", selection: $settings.voicePack) {
                Text("😱 Classic").tag("classic")
                Text("💋 Sexy").tag("sexy")
                Text("🤬 Angry").tag("angry")
                Text("🐐 Goat").tag("goat")
                Text("🤖 Robot").tag("robot")
                Text("😵 Wilhelm").tag("wilhelm")
            }
            .pickerStyle(.segmented)
            
            // Sensitivity slider
            VStack(alignment: .leading) {
                Text("Sensitivity: \(settings.sensitivity, specifier: "%.2f")g")
                Slider(value: $settings.sensitivity, in: 0.05...0.50)
            }
            
            // Cooldown
            VStack(alignment: .leading) {
                Text("Cooldown: \(Int(settings.cooldown * 1000))ms")
                Slider(value: $settings.cooldown, in: 0.1...2.0)
            }
            
            // Launch at login
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
            
            Divider()
            
            Button("Quit SlapMac") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 300)
    }
}
```

---

## 🎨 UI Design

### Menu Bar Icon
- System icon: `hand.raised.fill`
- Custom: 18x18pt monochrome PNG
- Show slap count badge when > 0

### Settings Window
- Compact (300x400pt)
- Dark mode by default
- Vibrant materials (VisualEffectView)

### Colors
- Background: System dark appearance
- Accent: Gradient (#ff6b6b → #feca57)
- Text: Primary/secondary system colors

---

## 📦 Sound Assets

### Recording Strategy
Since pre-recorded > TTS for comedic timing:

**Option 1: Record ourselves** (5 mins)
- Use Voice Memos app
- Record each phrase with personality
- Export as WAV (uncompressed, low latency)

**Option 2: Use macOS say command + effects**
```bash
# Generate robot voice
say -v "Zarvox" "ERROR 404" -o robot_1.aiff
# Convert to WAV for lower latency
afconvert robot_1.aiff robot_1.wav -f WAVE
```

**Option 3: Freesound.org** (CC0 sounds)
- Search "ouch", "wilhelm scream", "goat"
- Download and trim

### Recommended: Option 1 (Record)
- 5-6 phrases per pack
- 1-2 seconds each
- WAV format (44100Hz, 16-bit)

---

## 🔒 Permissions & Sandboxing

### Entitlements (SlapMac.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <!-- No sandbox for HID access -->
    <key>com.apple.security.app-sandbox</key>
    <false/>
    
    <!-- User-selected file access (for custom sounds) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

**Note:** Sandboxed apps CANNOT access IOKit HID devices. Must disable sandbox.

### Notarization
- Code signing required for distribution
- Notarization for Gatekeeper compliance
- Can distribute via: Direct download, Homebrew, or Developer ID

---

## 🚀 Deployment Options

### 1. Direct Download (Easiest)
- Build Release .app
- Codesign + notarize
- Host on GitHub Releases
- DMG for pretty installer

### 2. Homebrew
```ruby
# slapmac.rb
class Slapmac < Formula
  desc "Slap your MacBook, it screams back"
  homepage "https://github.com/artyomx33/slapmac"
  url "https://github.com/artyomx33/slapmac/releases/download/v1.0/SlapMac-1.0.dmg"
  sha256 "..."
  
  def install
    prefix.install "SlapMac.app"
  end
end
```

### 3. Mac App Store (Not possible)
- IOKit HID access blocked in sandbox
- Alternative: Submit to Setapp

---

## 📋 Build Steps (Implementation Order)

### Phase 1: Skeleton (30 min)
1. Create Xcode project (App template)
2. Configure MenuBarExtra in App struct
3. Add LSUIElement to Info.plist
4. Build basic SettingsView
5. Test menu bar appears

### Phase 2: Motion (45 min)
1. Add MotionDetector class with IOKit HID
2. Implement HID device matching (Apple SPU)
3. Parse 22-byte HID reports
4. Add threshold detection
5. Test with print statements

### Phase 3: Audio (30 min)
1. Record/generate sound files
2. Add to Resources/sounds/
3. Implement AudioEngine
4. Test volume mapping
5. Wire to slap detection

### Phase 4: Polish (30 min)
1. Add slap counter persistence
2. Settings UI refinement
3. App icon design
4. Code signing setup
5. Build Release version

### Phase 5: Distribution (15 min)
1. Create DMG
2. Notarize
3. GitHub Release
4. Update README

---

## 🐛 Known Issues & Solutions

### Issue 1: No accelerometer on M1 base model
**Solution:** Check hardware at launch, show warning if no SPU detected

### Issue 2: Sandboxing blocks HID
**Solution:** Disable app sandbox in entitlements

### Issue 3: Audio doesn't play
**Solution:** Ensure AVAudioPlayer is instance variable (not local)

### Issue 4: False positives from typing
**Solution:** Default threshold 0.15g+ (typing ~0.02g)

---

## 🎯 Success Criteria

- [ ] Menu bar icon appears on launch
- [ ] Slapping MacBook triggers sound
- [ ] Volume scales with slap force
- [ ] Slap counter persists across launches
- [ ] Settings UI works (voice pack, sensitivity)
- [ ] No dock icon visible
- [ ] Quit button works
- [ ] Runs on Apple Silicon (M2+)

---

## 📚 References

- Research: `life/areas/projects/slapmac-native/research/`
- Prior art: https://github.com/taigrr/spank
- IOKit HID: https://github.com/olvier/apple-silicon-accelerometer
- MenuBarExtra: WWDC 2022 session

---

**Ready to build!** 🦞
