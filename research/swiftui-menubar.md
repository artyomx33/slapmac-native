# SwiftUI Menu Bar App Research for SlapMac Native

**Date:** 2026-03-27  
**Project:** slapmac-native  
**Purpose:** Research for building a native macOS menu bar app that detects laptop slaps via accelerometer and plays sound effects

---

## 1. SwiftUI Menu Bar App Patterns

### Basic Structure with MenuBarExtra

SwiftUI provides the `MenuBarExtra` scene type (introduced WWDC 2022) for creating menu bar utilities:

```swift
import SwiftUI

@main
struct SlapMacApp: App {
    var body: some Scene {
        MenuBarExtra(
            "SlapMac",
            systemImage: "hand.raised.fill"
        ) {
            ContentView()
                .frame(width: 300, height: 200)
        }
        .menuBarExtraStyle(.window)
    }
}
```

Two styles available:
- `.menu` - Traditional dropdown menu (default)
- `.window` - Flexible window style with SwiftUI content (recommended for utilities)

### Hiding Dock Icon (LSUIElement)

For menu bar-only apps, hide from Dock and app switcher:

**Option 1: Info.plist** (Recommended)
```xml
<key>LSUIElement</key>
<true/>
```
Or in Xcode: Info tab → "Application is agent (UIElement)" = YES

**Option 2: Programmatic** (for dynamic behavior)
```swift
// Hide dock icon
NSApp.setActivationPolicy(.accessory)

// Show dock icon when needed (e.g., for preferences window)
NSApp.setActivationPolicy(.regular)
NSApp.activate(ignoringOtherApps: true)
```

⚠️ **Important:** You can only go from `.regular` → `.accessory` at runtime if NOT set in Info.plist. Set LSUIElement in plist, then programmatically switch to regular when needed.

### Custom Menu Bar Icon

```swift
MenuBarExtra {
    ContentView()
} label: {
    Label("SlapMac", image: "menuBarIcon")
}
```

For proper sizing with custom PNG:
```swift
let image: NSImage = {
    let ratio = $0.size.height / $0.size.width
    $0.size.height = 18
    $0.size.width = 18 / ratio
    return $0
}(NSImage(named: "MenuBarIcon")!)

Image(nsImage: image)
```

### Quit Button (Required for LSUIElement apps)

Since dock icon is hidden, provide quit functionality:

```swift
Button("Quit", systemImage: "xmark.circle.fill") {
    NSApp.terminate(nil)
}
.keyboardShortcut("q")
```

---

## 2. Accelerometer Access on macOS

### Key Finding: No Public API

Apple Silicon MacBooks have a built-in MEMS accelerometer + gyroscope (Bosch BMI286 IMU), but **there is NO public API**:

- ❌ CoreMotion - iOS only, doesn't work on macOS
- ❌ IOKit Motion API - Not exposed for Sudden Motion Sensor
- ✅ IOKit HID - Only working approach via undocumented interfaces

### How It Works

The sensor is managed by the **Sensor Processing Unit (SPU)** and appears in IOKit as:
- Device: `AppleSPUHIDDevice`
- Vendor usage page: `0xFF00`
- Usage: `3` (accelerometer), `9` (gyroscope)
- Driver: `AppleSPUHIDDriver`

### Verify Your Mac Has It

```bash
ioreg -l -w0 | grep -A5 AppleSPUHIDDevice
```

### Data Format

- HID reports: 22 bytes
- X, Y, Z: int32 little-endian at offsets 6, 10, 14
- Scale: divide by 65536 to get values in **g** (gravity units)
- Sample rate: ~800Hz native, ~100Hz practical via HID callbacks

### Swift Implementation Approach

Since this requires IOKit HID access, you'll need:

1. **C/Objective-C wrapper** for IOKit HID functions
2. **Swift bindings** to bridge to your app

Key IOKit functions:
```c
IOHIDDeviceCreate(kCFAllocatorDefault, device)
IOHIDDeviceRegisterInputReportCallback(device, report, length, callback, context)
IOHIDDeviceOpen(device, kIOHIDOptionsTypeSeizeDevice)
```

### Reference Projects

| Project | Language | Notes |
|---------|----------|-------|
| [olvvier/apple-silicon-accelerometer](https://github.com/olvvier/apple-silicon-accelerometer) | Python | Complete implementation with filters |
| [taigrr/spank](https://github.com/taigrr/spank) | Go | Slap detection with audio feedback |
| [technitish9123/slapmymac](https://github.com/technitish9123/slapmymac) | Swift | **Full SwiftUI menu bar app!** |

### Hardware Compatibility

- ✅ MacBook Pro M2/M3/M4 (all variants)
- ✅ MacBook Air M2/M3
- ✅ MacBook Pro M1 Pro (specific SKU)
- ❌ MacBook Pro M1 base model
- ❌ Mac Studio / Mac mini / Mac Pro
- ❌ Intel Macs

### Requirements

- **Must run as root/sudo** - IOKit HID requires elevated privileges
- For distribution, user must authorize or use launchd with root

---

## 3. Slap Detection Algorithm

### Detection Approaches

Based on analysis of existing projects (`spank`, `slapmymac`, `olvvier/accelerometer`):

#### 1. Simple Threshold (Good for Start)
```swift
let threshold: Double = 0.15  // g-force above gravity

func detectSlap(accel: (x: Double, y: Double, z: Double)) -> Bool {
    // Calculate magnitude
    let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
    
    // At rest: magnitude ≈ 1.0g (gravity)
    // During slap: magnitude spikes significantly
    let dynamicAcceleration = abs(magnitude - 1.0)
    
    return dynamicAcceleration > threshold
}
```

#### 2. Peak Detection with Cooldown (Recommended)
```swift
class SlapDetector {
    private var lastSlapTime: Date = .distantPast
    private let cooldown: TimeInterval = 0.75  // seconds
    private let threshold: Double = 0.15
    
    func processSample(accel: (x: Double, y: Double, z: Double)) -> Bool {
        let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
        let dynamicAccel = abs(magnitude - 1.0)
        
        guard Date().timeIntervalSince(lastSlapTime) > cooldown else {
            return false  // Still in cooldown
        }
        
        if dynamicAccel > threshold {
            lastSlapTime = Date()
            return true
        }
        
        return false
    }
}
```

#### 3. Advanced Detection (from `spank` project)
Uses multiple signal processing techniques:
- **STA/LTA** (Short-Term Average / Long-Term Average) - detects sudden changes
- **CUSUM** - cumulative sum for drift detection
- **Kurtosis** - measures "peakiness" of signal
- **MAD** (Median Absolute Deviation) - robust outlier detection

### Sensitivity Thresholds

| Threshold | Sensitivity | Use Case |
|-----------|-------------|----------|
| 0.05 - 0.10 | Very High | Light taps, finger touches |
| 0.15 - 0.25 | Medium | Normal slaps |
| 0.30 - 0.50 | Low | Hard impacts only |

### Filtering (from `macimu` library)

```python
# High-pass filter to remove gravity component
# Butterworth 4th order, -24dB/oct
filtered = high_pass(samples, cutoff=10.0, rate=100.0, order=4)

# Or use Kalman filter for gravity removal
gravity_removed = remove_gravity(samples)

# Peak detection with minimum spacing
peaks = peak_detect(magnitudes, threshold=1.2, min_spacing=50)
```

### Dynamic Volume Scaling

```swift
func calculateVolume(from acceleration: Double) -> Float {
    let minVolume: Float = 0.3
    let maxVolume: Float = 1.0
    let maxAccel: Double = 2.0  // Cap at 2g
    
    let normalized = min(acceleration / maxAccel, 1.0)
    return minVolume + (maxVolume - minVolume) * Float(normalized)
}
```

---

## 4. Audio Playback with AVFoundation

### Basic Audio Player Setup

```swift
import AVFoundation

class AudioEngine {
    private var player: AVAudioPlayer?
    
    func playSound(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}
```

### Volume and Speed Control

```swift
// Volume (0.0 to 1.0)
player?.volume = 0.8

// Playback rate (0.5 = half speed, 2.0 = double)
player?.enableRate = true
player?.rate = 1.5

// Number of loops (-1 = infinite)
player?.numberOfLoops = 0
```

### Playing Multiple Sounds

```swift
class SoundPackManager {
    private var players: [AVAudioPlayer] = []
    
    func playRandom(from sounds: [String]) {
        guard let sound = sounds.randomElement(),
              let url = Bundle.main.url(forResource: sound, withExtension: nil) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            players.append(player)
            
            // Clean up finished players
            players.removeAll { !$0.isPlaying }
        } catch {
            print("Error playing sound: \(error)")
        }
    }
}
```

### Custom Sound Packs

Allow users to add their own sounds:

```swift
let appSupportURL = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask)
    .first?
    .appendingPathComponent("SlapMac/CustomSounds")

// Load from custom directory
let sounds = try? FileManager.default
    .contentsOfDirectory(at: appSupportURL!, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() in ["mp3", "wav", "aiff"] }
```

---

## 5. App Lifecycle Management

### ScenePhase for Background Apps

```swift
import SwiftUI

@main
struct SlapMacApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "hand.raised.fill")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                print("App in background - keep sensor running")
            case .inactive:
                print("App inactive")
            case .active:
                print("App active")
            @unknown default:
                break
            }
        }
    }
}
```

⚠️ **Critical for SlapMac:** Menu bar apps with `.window` style stay effectively "active" even when window is closed. The sensor monitoring should run continuously.

### Persistent Service Pattern

```swift
class SlapDetectionService: ObservableObject {
    static let shared = SlapDetectionService()
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        // Start accelerometer monitoring
    }
    
    func stop() {
        isRunning = false
        // Stop monitoring
    }
}
```

### Launch at Login

Modern approach (macOS 13+):
```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) {
    do {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    } catch {
        print("Failed to set launch at login: \(error)")
    }
}

// Check status
let status = SMAppService.mainApp.status
// .enabled, .notFound, .notRegistered
```

Legacy approach (pre-macOS 13):
```swift
import ServiceManagement

let helperBundleId = "com.yourcompany.SlapMacLauncher"
SMLoginItemSetEnabled(helperBundleId as CFString, true)
```

Requires separate helper app target. See [sindresorhus/LaunchAtLogin-Legacy](https://github.com/sindresorhus/LaunchAtLogin-Legacy).

### Running as Root (for Sensor Access)

Since IOKit HID requires root, options:

1. **LaunchDaemon** (Recommended for production)
   - Install plist to `/Library/LaunchDaemons/`
   - Runs as root at boot
   - No sudo prompt after initial setup

2. **SMPrivilegedExecutables** (Modern)
   - Helper tool with elevated privileges
   - XPC communication between UI and helper

3. **Sudo wrapper** (Development)
   ```bash
   sudo /Applications/SlapMac.app/Contents/MacOS/SlapMac
   ```

### Sample LaunchDaemon Plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourcompany.SlapMac</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/SlapMac.app/Contents/MacOS/SlapMac</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

---

## 6. Project Structure Reference

Based on `technitish9123/slapmymac`:

```
SlapMac/
├── Sources/
│   ├── CHIDAccelerometer/     # C wrapper for IOKit HID
│   │   ├── CHIDAccelerometer.c
│   │   └── include/
│   └── SlapMac/
│       ├── App/
│       │   └── SlapMacApp.swift       # @main entry point
│       ├── Audio/
│       │   ├── AudioEngine.swift      # AVAudioPlayer wrapper
│       │   ├── SoundPack.swift        # Sound pack model
│       │   └── SoundPackManager.swift # Loading/playing sounds
│       ├── Sensor/
│       │   ├── AccelerometerManager.swift  # IOKit interface
│       │   ├── SlapDetector.swift          # Detection algorithm
│       │   └── SlapEvent.swift             # Event model
│       ├── State/
│       │   ├── AppState.swift         # Global app state
│       │   └── Preferences.swift      # User settings
│       ├── UI/
│       │   ├── MenuBarView.swift      # Main menu bar UI
│       │   ├── SettingsView.swift     # Preferences panel
│       │   └── SoundPackPicker.swift  # Sound selection
│       └── Utilities/
│           ├── Constants.swift
│           └── LaunchAtLogin.swift
└── Resources/
    └── SoundPacks/              # Bundled audio files
```

---

## 7. Key Implementation Notes

### Development Checklist

- [ ] Create menu bar extra with `.window` style
- [ ] Set `LSUIElement` in Info.plist
- [ ] Add quit button to UI
- [ ] Implement C/ObjC IOKit HID wrapper
- [ ] Parse 22-byte HID reports (offsets 6, 10, 14)
- [ ] Implement slap detection algorithm with cooldown
- [ ] Add AVAudioPlayer for sound playback
- [ ] Support dynamic volume scaling
- [ ] Add preferences (sensitivity, volume, cooldown)
- [ ] Implement launch at login
- [ ] Handle root privilege requirements

### Important Considerations

1. **Root Access** - Plan for distribution: LaunchDaemon vs privileged helper
2. **Hardware Variations** - Test across different MacBook models
3. **macOS Updates** - Undocumented API could break
4. **Battery Impact** - Continuous sensor polling (~100Hz)
5. **False Positives** - Typing, movement, vibrations can trigger

### Related Projects to Study

| Project | What to Learn |
|---------|---------------|
| `spank` | Detection algorithms, launchd setup, Go→Swift porting |
| `slapmymac` | Full SwiftUI architecture, custom sound packs |
| `apple-silicon-accelerometer` | IOKit HID implementation, filtering |
| `Knock` (tryknock.app) | Commercial product, UX patterns |
| `Haptyk` | Typing detection via accelerometer |

---

## Sources

1. [nilcoalescing.com - Build macOS menu bar utility](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
2. [sarunw.com - Create mac menu bar app](https://sarunw.com/posts/swiftui-menu-bar-app/)
3. [Apple Developer - MenuBarExtra](https://developer.apple.com/documentation/SwiftUI/MenuBarExtra)
4. [olvvier/apple-silicon-accelerometer](https://github.com/olvvier/apple-silicon-accelerometer)
5. [taigrr/spank](https://github.com/taigrr/spank)
6. [technitish9123/slapmymac](https://github.com/technitish9123/slapmymac)
7. [Sesame Disk - MEMS Accelerometer Access](https://sesamedisk.com/access-mems-accelerometer-apple-silicon/)
8. [nilcoalescing.com - Launch at Login](https://nilcoalescing.com/blog/LaunchAtLoginSetting/)
9. [sindresorhus/LaunchAtLogin-Legacy](https://github.com/sindresorhus/LaunchAtLogin-Legacy)
