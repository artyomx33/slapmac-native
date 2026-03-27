//
//  SlapCounter.swift
//  SlapMac
//
//  Persistent slap counting
//

import Foundation
import Combine

class SlapCounter: ObservableObject {
    @Published var count: Int {
        didSet {
            UserDefaults.standard.set(count, forKey: "slapCount")
        }
    }
    
    init() {
        count = UserDefaults.standard.integer(forKey: "slapCount")
    }
    
    func increment() {
        count += 1
    }
    
    func reset() {
        count = 0
    }
}
