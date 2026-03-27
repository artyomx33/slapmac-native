//
//  ContentView.swift
//  SlapMac
//
//  Main settings window
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var motionDetector: MotionDetector
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var slapCounter: SlapCounter
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("👋💻")
                    .font(.system(size: 48))
                Text("SlapMac")
                    .font(.system(size: 28, weight: .bold))
                Text("Slap your Mac. It screams back.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Slap Counter
            VStack(spacing: 4) {
                Text("\(slapCounter.count)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.linearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                Text("Lifetime Slaps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Status
            HStack {
                Circle()
                    .fill(motionDetector.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(motionDetector.isRunning ? "Listening for slaps..." : "Motion detection off")
                    .font(.caption)
                Spacer()
            }
            
            // Voice Pack
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Pack")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $settings.voicePack) {
                    Text("😱 Classic").tag("classic")
                    Text("💋 Sexy").tag("sexy")
                    Text("🤬 Angry").tag("angry")
                    Text("🐐 Goat").tag("goat")
                    Text("🤖 Robot").tag("robot")
                    Text("😵 Wilhelm").tag("wilhelm")
                }
                .pickerStyle(.menu)
            }
            
            // Sensitivity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sensitivity")
                        .font(.caption)
                    Spacer()
                    Text("\(settings.sensitivity, specifier: "%.2f")g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.sensitivity, in: 0.05...0.50)
            }
            
            // Cooldown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cooldown")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(settings.cooldown * 1000))ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.cooldown, in: 0.1...2.0)
            }
            
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
            
            Divider()
            
            Button("Quit SlapMac") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .onAppear {
            motionDetector.startMonitoring { force in
                audioEngine.playReaction(force: force, voicePack: settings.voicePack)
                slapCounter.increment()
            }
        }
    }
}
