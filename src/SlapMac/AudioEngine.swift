//
//  AudioEngine.swift
//  SlapMac
//
//  AVAudioPlayer-based sound engine with volume control
//

import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    private var player: AVAudioPlayer?
    
    // Voice packs with their phrases
    private let voicePacks: [String: [String]] = [
        "classic": ["ouch_1", "ouch_2", "hey", "stop_it", "that_hurts", "why"],
        "sexy": ["oh_yeah_1", "oh_yeah_2", "mmm", "do_it_again", "harder", "oh_baby"],
        "angry": ["hey_loud", "ouch_loud", "stop_loud", "what_the", "idiot", "seriously"],
        "goat": ["baaa_1", "baaa_2", "maah", "bleeeet", "goat_scream", "meeeeh"],
        "robot": ["error_404", "damage_detected", "system_hurt", "malfunction", "ouch_robot", "beep_boop"],
        "wilhelm": ["wilhelm_1", "wilhelm_2", "wilhelm_3", "aaaaaaah", "noooooo", "scream_long"]
    ]
    
    func playReaction(force: Double, voicePack: String) {
        // Select random sound from pack
        guard let sounds = voicePacks[voicePack],
              let sound = sounds.randomElement(),
              let url = Bundle.main.url(forResource: "sounds/\(voicePack)/\(sound)", withExtension: "wav") else {
            // Fallback to speech synthesis if sound file missing
            speakFallback(force: force)
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            
            // Map force (0.05-0.50) to volume (0.3-1.0)
            let minForce: Double = 0.05
            let maxForce: Double = 0.50
            let normalized = (force - minForce) / (maxForce - minForce)
            let volume = 0.3 + (normalized * 0.7)
            player?.volume = Float(min(1.0, max(0.3, volume)))
            
            player?.play()
        } catch {
            print("Audio error: \(error)")
            speakFallback(force: force)
        }
    }
    
    private func speakFallback(force: Double) {
        // Fallback to text-to-speech if audio files not found
        let utterance = AVSpeechUtterance(string: "Ouch!")
        utterance.volume = Float(min(1.0, max(0.3, (force - 0.05) / 0.45 * 0.7 + 0.3)))
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        AVSpeechSynthesizer().speak(utterance)
    }
}
