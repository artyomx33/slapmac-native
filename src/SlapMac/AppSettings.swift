//
//  AppSettings.swift
//  SlapMac
//
//  User preferences
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var voicePack: String {
        didSet { UserDefaults.standard.set(voicePack, forKey: "voicePack") }
    }
    
    @Published var sensitivity: Double {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "sensitivity") }
    }
    
    @Published var cooldown: Double {
        didSet { UserDefaults.standard.set(cooldown, forKey: "cooldown") }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    init() {
        voicePack = UserDefaults.standard.string(forKey: "voicePack") ?? "classic"
        sensitivity = UserDefaults.standard.double(forKey: "sensitivity")
        if sensitivity == 0 { sensitivity = 0.15 }  // Default
        cooldown = UserDefaults.standard.double(forKey: "cooldown")
        if cooldown == 0 { cooldown = 0.75 }  // Default 750ms
        launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
}
