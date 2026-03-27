//
//  MotionDetector.swift
//  SlapMac
//
//  IOKit HID accelerometer access for Apple Silicon Macs
//

import Foundation
import IOKit.hid

class MotionDetector: ObservableObject {
    @Published var isRunning = false
    @Published var lastForce: Double = 0
    
    private var manager: IOHIDManager?
    private var callback: ((Double) -> Void)?
    private var lastSlapTime: Date = .distantPast
    private var settings = AppSettings()
    
    func startMonitoring(onSlap: @escaping (Double) -> Void) {
        self.callback = onSlap
        
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        // Match Apple SPU HID device (Apple Silicon accelerometer)
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: 0x05ac,  // Apple
            kIOHIDDeviceUsagePageKey: 0xFF00,  // Vendor-defined
            kIOHIDDeviceUsageKey: 3  // Accelerometer
        ]
        
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        
        // Register callback
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterInputValueCallback(manager, motionCallback, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if result == kIOReturnSuccess {
            isRunning = true
            print("✅ Motion detector started")
        } else {
            print("❌ Failed to open HID manager: \(result)")
            isRunning = false
        }
    }
    
    func stopMonitoring() {
        if let manager = manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        isRunning = false
    }
    
    private let motionCallback: IOHIDValueCallback = { context, result, sender, value in
        guard result == kIOReturnSuccess else { return }
        
        let detector = Unmanaged<MotionDetector>.fromOpaque(context!).takeUnretainedValue()
        detector.handleMotionValue(value)
    }
    
    private func handleMotionValue(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usage = IOHIDElementGetUsage(element)
        let usagePage = IOHIDElementGetUsagePage(element)
        
        // We need to parse the raw HID report for X, Y, Z
        // Report format: 22 bytes, X/Y/Z as int32 at offsets 6, 10, 14
        
        guard let reportData = IOHIDValueGetBytePtr(value) else { return }
        let reportLength = IOHIDValueGetLength(value)
        
        guard reportLength >= 22 else { return }
        
        // Parse int32 values (little-endian)
        let x = parseInt32(reportData, offset: 6)
        let y = parseInt32(reportData, offset: 10)
        let z = parseInt32(reportData, offset: 14)
        
        // Convert to g-force (divide by 65536)
        let xg = Double(x) / 65536.0
        let yg = Double(y) / 65536.0
        let zg = Double(z) / 65536.0
        
        // Calculate magnitude
        let magnitude = sqrt(xg*xg + yg*yg + zg*zg)
        
        // Check cooldown
        let now = Date()
        guard now.timeIntervalSince(lastSlapTime) > settings.cooldown else { return }
        
        // Detect slap
        if magnitude > settings.sensitivity {
            lastSlapTime = now
            lastForce = magnitude
            DispatchQueue.main.async {
                self.callback?(magnitude)
            }
        }
    }
    
    private func parseInt32(_ ptr: UnsafePointer<UInt8>, offset: Int) -> Int32 {
        let bytes = ptr.advanced(by: offset)
        return Int32(bytes[0]) | 
               (Int32(bytes[1]) << 8) |
               (Int32(bytes[2]) << 16) |
               (Int32(bytes[3]) << 24)
    }
}
