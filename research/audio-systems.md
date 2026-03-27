# Audio Systems Research for SlapMac Native

**Date:** 2026-03-27  
**Project:** SlapMac Native - Slap detection macOS app  
**Research Focus:** Audio playback, voice packs, and dynamic volume control

---

## 1. AVFoundation Audio Playback Best Practices (Short Sound Clips)

### AVAudioPlayer Overview
- **Primary class** for audio playback in macOS/iOS apps
- Part of `AVFoundation` framework
- Supports formats: MP3, WAV, CAF, AAC, and more

### Critical Best Practices

#### 1. Retain the Player Instance
```swift
// MUST define as instance variable - NOT local
var player: AVAudioPlayer?  // ✅ Correct

func playSound() {
    let localPlayer = AVAudioPlayer(...)  // ❌ Wrong - deallocates immediately
    localPlayer.play()  // Sound won't play
}
```
- If `AVAudioPlayer` is local to a function, it gets deallocated immediately after `.play()`
- Must be stored as property/variable that persists while sound plays

#### 2. Basic Implementation Pattern
```swift
import AVFoundation

class SoundPlayer {
    var audioPlayer: AVAudioPlayer?
    
    func playSound(named: String) {
        guard let path = Bundle.main.path(forResource: named, ofType: nil) else {
            return
        }
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()  // Pre-buffer for lower latency
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
    }
}
```

#### 3. Performance Tips for Short Clips
| Technique | Benefit |
|-----------|---------|
| `prepareToPlay()` | Pre-buffers audio, reduces startup latency |
| Keep players in pool | Reuse instances for repeated sounds |
| Use WAV/CAF over MP3 | Lower CPU overhead for short sounds |
| Set `numberOfLoops = 0` | Ensure clean single playback |

#### 4. Volume Control
```swift
audioPlayer?.volume = 0.5  // 0.0 to 1.0 range
audioPlayer?.play()
```
- Volume can be adjusted dynamically during playback

---

## 2. Text-to-Speech vs Pre-Recorded Audio

### Comparison for SlapMac Use Case

| Factor | TTS (AVSpeechSynthesizer) | Pre-Recorded |
|--------|---------------------------|--------------|
| **Latency** | Higher (processing delay) | Lower (instant playback) |
| **Variety** | Unlimited phrases | Limited to recorded clips |
| **Personality** | Robotic/Siri-like | Can be expressive, funny |
| **File Size** | Small (code only) | Larger (audio assets) |
| **Offline** | ✅ Yes | ✅ Yes |
| **Control** | Pitch/rate adjustable | Volume only (unless processed) |

### Recommendation: **Pre-Recorded Audio**

For a slap-reaction app, pre-recorded audio is better because:
1. **Immediate feedback** - No synthesis delay
2. **Comedic timing** - Precise control over delivery
3. **Personality** - Human-recorded "ouch!" > robotic voice
4. **Predictable** - Same reaction every time

### TTS Option Details

**AVSpeechSynthesizer** (Modern, iOS 7+, macOS 10.14+)
```swift
import AVFoundation

let synthesizer = AVSpeechSynthesizer()
let utterance = AVSpeechUtterance(string: "Ouch! That hurt!")
utterance.volume = 1.0
utterance.rate = AVSpeechUtteranceDefaultSpeechRate
utterance.pitchMultiplier = 1.0  // 0.5-2.0 range
synthesizer.speak(utterance)
```

**NSSpeechSynthesizer** (Legacy, macOS 10.3+)
- Older API, not recommended for new projects
- Limited voice quality compared to AVSpeechSynthesizer

### Siri Voice Limitation
- Siri-quality voices are **NOT available** via public API
- Both `NSSpeechSynthesizer` and `AVSpeechSynthesizer` use system voices only
- Third-party AI TTS services (ElevenLabs, etc.) would require API calls

---

## 3. Bundling Audio Assets in macOS Apps

### Method 1: Bundle Resources (Recommended)

1. **Add files to Xcode project**
   - Drag audio files into project navigator
   - Check "Add to targets" - CRITICAL step
   - Ensures files appear in "Build Phases → Copy Bundle Resources"

2. **Access in code**
```swift
// Get URL from main bundle
if let path = Bundle.main.path(forResource: "ouch", ofType: "wav") {
    let url = URL(fileURLWithPath: path)
    // Use with AVAudioPlayer
}
```

### Method 2: Asset Catalogs (iOS-focused)
- Apple Technical Q&A QA1913 covers audio in asset catalogs
- Better for app thinning but more complex
- Not commonly used for macOS audio

### Method 3: Custom Bundles
```bash
# Create custom bundle for organizing assets
mkdir Sounds.bundle
cp *.mp3 Sounds.bundle/
```
```swift
// Access custom bundle
let bundleURL = Bundle.main.url(forResource: "Sounds", withExtension: "bundle")
let customBundle = Bundle(url: bundleURL!)
```

### File Organization Strategy
```
SlapMac.app/
├── Contents/
│   ├── Resources/
│   │   ├── sounds/
│   │   │   ├── pain/
│   │   │   │   ├── ouch_1.wav
│   │   │   │   ├── ouch_2.wav
│   │   │   │   └── ow_1.wav
│   │   │   ├── sexy/
│   │   │   │   └── ...
│   │   │   └── halo/
│   │   │       └── ...
```

---

## 4. Volume Control Based on Slap Force

### Force Detection → Audio Volume Mapping

**Core Concept:** Map accelerometer amplitude to audio volume

```swift
class SlapAudioController {
    var audioPlayer: AVAudioPlayer?
    
    // Map slap intensity (0.05-0.50 g-force) to volume (0.3-1.0)
    func playReaction(amplitude: Double) {
        let minAmplitude: Double = 0.05
        let maxAmplitude: Double = 0.50
        
        // Normalize to 0-1 range
        let normalized = (amplitude - minAmplitude) / (maxAmplitude - minAmplitude)
        let clamped = max(0, min(1, normalized))
        
        // Map to volume (don't go below 0.3 for audibility)
        let volume = 0.3 + (clamped * 0.7)
        
        audioPlayer?.volume = Float(volume)
        audioPlayer?.play()
    }
}
```

### Advanced: Pitch Modulation with Force

Using `AVAudioEngine` for real-time effects:

```swift
import AVFoundation

class ReactiveAudioEngine {
    var engine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    var pitchUnit: AVAudioUnitTimePitch!
    
    func setup() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        pitchUnit = AVAudioUnitTimePitch()
        
        engine.attach(playerNode)
        engine.attach(pitchUnit)
        
        // Connect: player -> pitch -> output
        engine.connect(playerNode, to: pitchUnit, format: nil)
        engine.connect(pitchUnit, to: engine.mainMixerNode, format: nil)
        
        try? engine.start()
    }
    
    func playWithIntensity(amplitude: Double) {
        // Harder slap = higher pitch shift
        let pitchShift = amplitude * 1000  // cents (100 cents = 1 semitone)
        pitchUnit.pitch = Float(pitchShift)
        
        // Also adjust volume
        playerNode.volume = Float(0.3 + amplitude)
        
        playerNode.play()
    }
}
```

### Reference: Spank Project Implementation

**Spank** (GitHub: `taigrr/spank`) is the most relevant existing implementation:

**Features:**
- Uses Apple Silicon accelerometer via IOKit HID
- Adjustable sensitivity with `--min-amplitude` (default: 0.05 g)
- Custom playback speed: `--speed 0.7` (slower/deeper) to `--speed 1.5` (faster)
- Cooldown period: default 750ms between triggers
- Multiple modes: Pain, Sexy (60 escalation levels), Halo, Custom

**Sensitivity Thresholds:**
- `0.05-0.10`: Very sensitive, light taps
- `0.15-0.30`: Balanced sensitivity
- `0.30-0.50`: Only strong impacts

---

## 5. Voice Modulation Libraries for macOS

### AudioKit (Recommended)

**GitHub:** `AudioKit/AudioKit`

**Features:**
- Audio synthesis, processing & analysis
- iOS, macOS (including Catalyst), tvOS support
- Swift Package Manager integration
- Free and open-source

**Key Components for Voice Modulation:**
```swift
import AudioKit

// Pitch shifter
let pitchShifter = AVAudioUnitTimePitch()
pitchShifter.pitch = 200  // cents (+/- 2400 cents = 2 octaves)

// Other useful effects:
// - AVAudioUnitVarispeed (speed change)
// - AVAudioUnitEQ (equalizer)
// - Reverb, delay, distortion via AVAudioUnitEffect
```

**Installation:**
```swift
// In Xcode: File → Add Packages...
// URL: https://github.com/AudioKit/AudioKit
```

### Native AVAudioEngine Effects

**Built-in AVAudioUnit types:**
| Effect | Class | Use Case |
|--------|-------|----------|
| Time/Pitch | `AVAudioUnitTimePitch` | Adjust pitch without speed |
| Varispeed | `AVAudioUnitVarispeed` | Speed change (affects pitch) |
| EQ | `AVAudioUnitEQ` | Frequency adjustment |
| Reverb | `AVAudioUnitReverb` | Spatial effects |
| Delay | `AVAudioUnitDelay` | Echo effects |
| Distortion | `AVAudioUnitDistortion` | Grunge/vintage effects |

### Example: Full Modulation Chain
```swift
func setupAudioChain() {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    
    // Effects chain
    let pitch = AVAudioUnitTimePitch()
    let reverb = AVAudioUnitReverb()
    let eq = AVAudioUnitEQ()
    
    // Configure
    pitch.pitch = -200  // Lower pitch (deeper voice)
    reverb.loadFactoryPreset(.cathedral)
    reverb.wetDryMix = 30
    
    // Connect chain
    engine.attach(player)
    engine.attach(pitch)
    engine.attach(reverb)
    engine.attach(eq)
    
    engine.connect(player, to: pitch, format: nil)
    engine.connect(pitch, to: reverb, format: nil)
    engine.connect(reverb, to: eq, format: nil)
    engine.connect(eq, to: engine.mainMixerNode, format: nil)
}
```

---

## Key GitHub References

| Project | URL | Relevance |
|---------|-----|-----------|
| **Spank** | `taigrr/spank` | Direct prior art - slap detection + audio |
| **AudioKit** | `AudioKit/AudioKit` | Full audio processing framework |
| **AudioStreamer** | `syedhali/AudioStreamer` | Streaming + real-time effects |
| **SwiftAudioPlayer** | `tanhakabir/SwiftAudioPlayer` | Streaming with AVAudioEngine |
| **macos-audio-devices** | `karaggeorge/macos-audio-devices` | System audio device control |

---

## Implementation Recommendations

### Phase 1: Basic (AVAudioPlayer)
- Bundle 10-20 pre-recorded "ouch" clips
- Random selection on slap detection
- Simple volume mapping to slap force

### Phase 2: Enhanced (AVAudioEngine)
- Real-time pitch shifting based on force
- Add reverb/delay for comedic effect
- Multiple voice packs (pain/sexy/halo modes)

### Phase 3: Advanced (AudioKit)
- Full synthesis capabilities
- Dynamic audio generation
- Professional audio effects chain

---

## Summary

| Component | Recommendation |
|-----------|---------------|
| **Audio Engine** | Start with `AVAudioPlayer`, upgrade to `AVAudioEngine` |
| **Voice Source** | Pre-recorded clips (not TTS) for personality |
| **Asset Bundling** | Standard bundle resources, organized by category |
| **Volume Control** | Linear mapping: slap amplitude → audio volume |
| **Voice Modulation** | `AVAudioUnitTimePitch` for pitch shifting |
| **Full Effects** | AudioKit framework for advanced processing |
