//
//  SlapMacApp.swift
//  SlapMac
//
//  Slap your MacBook. It screams back.
//

import SwiftUI

@main
struct SlapMacApp: App {
    @StateObject private var motionDetector = MotionDetector()
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var slapCounter = SlapCounter()
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        MenuBarExtra("SlapMac", systemImage: "hand.raised.fill") {
            ContentView()
                .environmentObject(motionDetector)
                .environmentObject(audioEngine)
                .environmentObject(slapCounter)
                .environmentObject(settings)
                .frame(width: 320, height: 450)
        }
        .menuBarExtraStyle(.window)
    }
}
