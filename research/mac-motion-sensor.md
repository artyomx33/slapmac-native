# Mac Motion Sensor Research - SlapMac Native

**Date:** 2026-03-27  
**Researcher:** Subagent  
**Target:** macOS Sudden Motion Sensor (SMS) / Accelerometer access for slap detection

---

## 1. Overview: Two Different Eras of Mac Motion Sensors

### Intel Macs (2005-2012)
- **Hardware:** PowerPC G4 → Intel-based laptops
- **Sensor:** Kionix KXM52-1050 three-axis accelerometer (MacBook Pro 15")
- **Dynamic Range:** +/- 2g, bandwidth up to 1.5 kHz
- **Resolution:** 8-bit (250 scale divisions)
- **Purpose:** Hard drive head parking when dropped
- **API:** IOKit with `AppleSMCLMUController` / SMCMotionSensor

### Apple Silicon Macs (M2/M3/M4/M5+)
- **Hardware:** M2, M3, M4, M5 chips (NOT M1 base models except M1 Pro)
- **Sensor:** Bosch BMI286 IMU (accelerometer + gyroscope)
- **Managed By:** Sensor Processing Unit (SPU)
- **Native Rate:** ~800Hz
- **Decimated Rate:** ~100Hz (default)
- **API:** IOKit HID via `AppleSPUHIDDevice` (UNDOCUMENTED)
- **Key Limitation:** NO public API or framework (CoreMotion unavailable on macOS)

> **⚠️ CRITICAL DISTINCTION:** M1 base model (2020 MacBook Air/Pro) does NOT have the SPU accelerometer. Only M1 Pro/Max and M2+ have it.

---

## 2. Access Methods

### Intel Macs - IOKit via SMC

```objc
// Original approach by Amit Singh
// Uses AppleSMCLMUController kernel extension

#include <IOKit/IOKitLib.h>

// Service matching for SMS
#define SMS_SERVICE "AppleSMCLMUController"

// Key IOKit calls:
// - IOServiceGetMatchingService()
// - IOServiceOpen()
// - IOConnectMethodStructureIStructureO() (deprecated in 10.5+)
```

**Key Files:**
- `IOKit/ps/IOPowerSources.h` - Not directly used but similar IOKit patterns
- SMC (System Management Controller) communication via user client

### Apple Silicon - IOKit HID

```python
# Modern approach via IOKit HID (from olvvier/apple-silicon-accelerometer)

import ctypes
from ctypes import cdll, Structure, c_void_p, c_uint32

# Load IOKit framework
iokit = cdll.LoadLibrary('/System/Library/Frameworks/IOKit.framework/IOKit')

# HID Manager setup
# - IOHIDManagerCreate()
# - IOHIDManagerSetDeviceMatching()
# - IOHIDManagerRegisterInputValueCallback()

# Device identification:
# - Vendor ID: Apple (0x05ac)
# - Usage Page: 0xFF00 (vendor-defined)
# - Usage: 3 (accelerometer), 9 (gyroscope)

# Report format: 22-byte HID reports
# X, Y, Z as int32 little-endian at byte offsets 6, 10, 14
# Divide by 65536 to get values in g (acceleration) or deg/s (gyro)
```

**Raw HID Report Parsing:**
```c
// From apple-silicon-accelerometer project
struct hid_report {
    uint8_t report_id;
    uint8_t unknown[5];
    int32_t x;        // offset 6
    int32_t y;        // offset 10
    int32_t z;        // offset 14
    // ... remaining bytes
};

// Conversion:
float accel_g = (float)raw_value / 65536.0f;
```

---

## 3. Code Examples

### Python (Apple Silicon) - Using macimu library

```python
from macimu import IMU
from macimu.filters import magnitude, remove_gravity, peak_detect

# Check availability
if not IMU.available():
    print("No IMU found - M1 base model or Intel Mac")
    return

# Basic reading
with IMU() as imu:
    # Get latest sample
    accel = imu.latest_accel()  # Sample(x, y, z) in g
    
    # Read all new samples since last call
    samples = imu.read_accel()
    for s in samples:
        print(f"x={s.x:.3f}g, y={s.y:.3f}g, z={s.z:.3f}g")

# Slap detection with filtering
with IMU() as imu:
    samples = imu.read_accel()
    
    # Remove gravity component (1g at rest)
    dynamic = remove_gravity(samples)
    
    # Calculate magnitude
    mags = [magnitude(s.x, s.y, s.z) for s in dynamic]
    
    # Peak detection
    hits = peak_detect(mags, threshold=0.5)  # 0.5g threshold
```

### Swift/Objective-C (Apple Silicon) - Direct IOKit HID

```swift
import IOKit.hid

class AccelerometerReader {
    var manager: IOHIDManager?
    var device: IOHIDDevice?
    
    func start() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        
        // Match Apple SPU HID device
        let matching = [
            kIOHIDVendorIDKey: 0x05ac,
            kIOHIDProductIDKey: 0x0000,  // Varies
            kIOHIDDeviceUsagePageKey: 0xFF00,
            kIOHIDDeviceUsageKey: 3  // Accelerometer
        ] as CFDictionary
        
        IOHIDManagerSetDeviceMatching(manager, matching)
        IOHIDManagerRegisterInputValueCallback(manager, { ... }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}
```

### Go (Apple Silicon) - From spank project

```go
// Key detection algorithm from spank
// Uses vibration detection: STA/LTA, CUSUM, kurtosis, peak/MAD

type DetectionConfig struct {
    MinAmplitude    float64  // default: 0.05 (g)
    CooldownMs      int      // default: 750
    PollingInterval time.Duration  // default: 10ms
    SampleBatchSize int      // default: 200
}

// Fast mode settings:
// - Polling: 4ms vs 10ms
// - Cooldown: 350ms vs 750ms  
// - Threshold: 0.18 vs 0.05
// - Batch: 320 vs 200
```

### C (Intel Macs) - Using UniMotion

```c
#include "unimotion.h"

// Detect hardware type
int type = detect_sms();
// Returns: SMS_TYPE_POWERBOOK, SMS_TYPE_MACBOOK, etc.

// Read sensor
float x, y, z;
int result = read_sms(type, &x, &y, &z);
// Values typically in raw sensor units, convert to g
```

---

## 4. Motion Detection Thresholds

### What Constitutes a "Slap"?

Based on analysis of existing projects:

| Threshold | Sensitivity | Use Case |
|-----------|-------------|----------|
| 0.05g | Very sensitive | Light taps, typing detection |
| 0.10-0.15g | Sensitive | Normal slaps |
| 0.18g | Balanced (fast mode) | Clear intentional slaps |
| 0.20-0.25g | Moderate | Harder slaps only |
| 0.30-0.50g | Low | Only strong impacts |

**Reference Values from Spank:**
- Default: `--min-amplitude 0.05` (g)
- Fast mode: `--min-amplitude 0.18` (g)
- Light taps: `0.05-0.10`
- Medium: `0.15-0.30`
- Strong: `0.30-0.50`

### Detection Algorithms

**1. Simple Threshold (Spank default)**
```python
if magnitude(x, y, z) > threshold:
    trigger()
```

**2. Peak Detection with Cooldown**
```python
last_trigger = 0
cooldown_ms = 750

for sample in samples:
    if magnitude(sample) > threshold:
        if now() - last_trigger > cooldown_ms:
            trigger()
            last_trigger = now()
```

**3. Advanced Vibration Detection (Spank)**
- STA/LTA (Short Term Average / Long Term Average)
- CUSUM (Cumulative Sum control chart)
- Kurtosis (measure of "tailedness")
- Peak/MAD (Median Absolute Deviation)

**4. High-Pass Filtering**
Remove gravity (1g at rest) to isolate dynamic acceleration:
```python
# Remove 1g gravity vector
dynamic_accel = total_accel - gravity_vector

# Or use Kalman filter (from macimu)
from macimu.filters import remove_gravity
dynamic = remove_gravity(samples)
```

---

## 5. Existing "Slap" / "Shake" Detection Apps

### Production Apps

| App | Platform | Type | Notes |
|-----|----------|------|-------|
| **Spank** | Apple Silicon | CLI tool | "Slap your MacBook, it yells back" - Open source, Go |
| **Knock** | Apple Silicon | GUI app | tryknock.app - Taps into actions |
| **SlapMac** | Apple Silicon | GUI app | slapmac.com - Commercial, similar to Spank |
| **Slap My Mac** | Apple Silicon | Web/Native | slap-my-mac.vercel.app |
| **Haptyk** | Apple Silicon | GUI app | haptyk.com - Typing → mechanical keyboard sounds |

### Libraries & Tools

| Project | Lang | Purpose | Link |
|---------|------|---------|------|
| **apple-silicon-accelerometer** | Python | IMU access library | github.com/olvvier/apple-silicon-accelerometer |
| **spank** | Go | Slap detection + audio | github.com/taigrr/spank |
| **macimu** | Python | High-level IMU Python pkg | pip install macimu |
| **mac-hardware-toys** | Python | Various hardware access | github.com/pirate/mac-hardware-toys |

### Legacy (Intel Macs)

| Project | Lang | Era | Status |
|---------|------|-----|--------|
| **SMSLib** | Obj-C | Intel | github.com/bitcartel/SMSLib |
| **UniMotion** | C | Intel/PowerPC | sourceforge.net/projects/unimotion |
| **SeisMac** | Obj-C | Intel | suitable.com/tools/seismac.html |
| **AMSTracker** | C | Intel/PowerPC | Amit Singh's original |
| **iRotar** | Obj-C | Intel | Screen rotation via SMS |

---

## 6. IOKit Documentation & References

### Apple Documentation
- **Core Motion**: developer.apple.com/documentation/coremotion/
  - ❌ NOT available on macOS - only iOS/iPadOS/watchOS
  
- **IOKit**: developer.apple.com/documentation/iokit
  - ✅ Available but sparse docs on HID specifics

- **IOKit HID**: developer.apple.com/documentation/iokit/iohidmanager
  - Key functions:
    - `IOHIDManagerCreate()`
    - `IOHIDManagerSetDeviceMatching()`
    - `IOHIDManagerRegisterInputReportCallback()`
    - `IOHIDDeviceOpen()`

### Key Technical References

**Apple Silicon HID Path:**
```
IOService:/AppleARMPE/arm-io/AppleT810xIO/spi0/AppleSPUHIDDevice
```

**Verification Command:**
```bash
# Check if your Mac has the SPU accelerometer
ioreg -l -w0 | grep -A5 AppleSPUHIDDevice

# Check system info
system_profiler SPDisplaysDataType | grep "Model Identifier"
```

### Historical References
- **Amit Singh's Mac OS X Internals** (osxbook.com)
  - Original reverse-engineering of SMS
  - "The Sudden Motion Sensor As A Human Interface Device"
  - Site currently down (DNS issues) but archived

---

## 7. Compatibility Matrix

| Mac Model | Has SMS | Library to Use | Notes |
|-----------|---------|----------------|-------|
| PowerBook G4 (2005+) | ✅ | UniMotion, SMSLib | Original SMS |
| MacBook (Intel, HDD) | ✅ | UniMotion, SMSLib | Kionix accelerometer |
| MacBook Pro (Intel) | ✅ | UniMotion, SMSLib | Kionix KXM52-1050 |
| MacBook Air (Intel) | ✅ | UniMotion, SMSLib | |
| MacBook Pro M1 (2020) | ❌ | N/A | No SPU |
| MacBook Air M1 (2020) | ❌ | N/A | No SPU |
| MacBook Pro M1 Pro/Max | ✅ | apple-silicon-accelerometer, spank | First with SPU |
| MacBook Pro M2/M3/M4 | ✅ | apple-silicon-accelerometer, spank | |
| MacBook Air M2/M3 | ✅ | apple-silicon-accelerometer, spank | |
| Mac Studio M4 Max | ✅ | apple-silicon-accelerometer | Confirmed working |

---

## 8. Implementation Recommendations for SlapMac

### For Apple Silicon (Primary Target)

**Approach 1: Swift Native with IOKit**
```swift
// Direct IOKit HID implementation
// Pros: No dependencies, native performance
// Cons: Undocumented API, may break with macOS updates
```

**Approach 2: Python Bridge**
```python
# Use macimu library, call from Swift via PythonKit
# Pros: Proven working, filters included
# Cons: Python dependency, requires sudo
```

**Approach 3: Port spank's Go algorithm to Swift**
```swift
// Spank is MIT licensed - can port detection logic
// Pros: Battle-tested thresholds, multiple detection modes
// Cons: Need to reimplement Go → Swift
```

### Key Implementation Details

1. **Require sudo**: IOKit HID access requires elevated privileges
2. **Hardware detection**: Check `IMU.available()` or equivalent before starting
3. **Sample rate**: Default ~100Hz is sufficient for slap detection
4. **Cooldown**: Essential to prevent rapid-fire triggers (750ms default)
5. **Gravity removal**: Subtract ~1g resting gravity for clean detection

### Suggested Thresholds for SlapMac

```swift
struct SlapConfig {
    // Conservative (default)
    static let normal = SlapConfig(
        threshold: 0.15,      // g-force
        cooldownMs: 750,
        pollingMs: 10
    )
    
    // Responsive mode
    static let sensitive = SlapConfig(
        threshold: 0.08,
        cooldownMs: 500,
        pollingMs: 5
    )
    
    // Only hard slaps
    static let insensitive = SlapConfig(
        threshold: 0.30,
        cooldownMs: 1000,
        pollingMs: 10
    )
}
```

---

## 9. Security & Sandbox Considerations

⚠️ **Critical Limitations:**

1. **No App Store distribution**: IOKit HID requires `com.apple.security.device.usb` entitlement or running outside sandbox
2. **Requires root/sudo**: AppleSPUHIDDevice access requires elevated privileges
3. **Undocumented API**: Apple may change/break this in future macOS updates
4. **Not for medical use**: Sensor accuracy not certified

**Distribution Options:**
- Direct download (DMG)
- Homebrew: `brew install --cask slapmac`
- GitHub Releases
- **NOT** Mac App Store compatible

---

## 10. References & Links

### GitHub Repositories
- https://github.com/taigrr/spank - Slap detection in Go
- https://github.com/olvvier/apple-silicon-accelerometer - Python IMU library
- https://github.com/bitcartel/SMSLib - Intel Mac SMS library
- https://github.com/shiffman/Sudden-Motion-Sensor-Processing - Processing library
- https://github.com/greenflute/iRotar - Screen rotation via SMS

### Documentation
- https://medium.com/@oli.bourbonnais/your-macbook-has-an-accelerometer-and-you-can-read-it-in-real-time-in-python-28d9395fb180
- https://news.ycombinator.com/item?id=47084000 - HN discussion
- https://ubos.tech/news/unlocking-apple-silicon-macs-hidden-accelerometer-open%E2%80%91source-project-review/

### Legacy
- https://unimotion.sourceforge.net/ - UniMotion C library
- http://suitable.com/smslib.html - SMSLib original site

---

## Summary

For SlapMac Native implementation:

1. **Target Apple Silicon** (M2+, M1 Pro/Max) - this is where the market is
2. **Use IOKit HID** via `AppleSPUHIDDevice` - only viable API path
3. **Port/adapt from spank** - MIT licensed, proven detection algorithms
4. **Implement configurable thresholds** - 0.05g to 0.50g range
5. **Require elevated privileges** - unavoidable for HID access
6. **Distribute outside App Store** - sandbox incompatible

The "slap" threshold should start at **0.15g** for balanced detection, with user-adjustable sensitivity from **0.05g** (very sensitive) to **0.50g** (only hard slaps).
