//
//  NetworkSpeedMonitor.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/29/26.
//
import Foundation
import Combine

class NetworkSpeedMonitor: ObservableObject {
    
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    
    private var lastReceived: UInt64 = 0
    private var lastSent: UInt64 = 0
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateSpeed()
        }
    }
    
    private func updateSpeed() {
        let data = getNetworkBytes()
        
        let down = data.received - lastReceived
        let up = data.sent - lastSent
        
        lastReceived = data.received
        lastSent = data.sent
        
        DispatchQueue.main.async {
            self.downloadSpeed = Double(down) / 1024.0
            self.uploadSpeed = Double(up) / 1024.0
        }
    }
    
    private func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        var received: UInt64 = 0
        var sent: UInt64 = 0
        
        if getifaddrs(&addrs) == 0 {
            var pointer = addrs
            
            while pointer != nil {
                let interface = pointer!.pointee
                let name = String(cString: interface.ifa_name)
                
                // en0 = WiFi, en1 = Ethernet (usually)
                if name == "en0" || name == "en1" {
                    
                    if let data = interface.ifa_data {
                        let stats = data.assumingMemoryBound(to: if_data.self).pointee
                        received += UInt64(stats.ifi_ibytes)
                        sent += UInt64(stats.ifi_obytes)
                    }
                }
                
                pointer = interface.ifa_next
            }
        }
        
        freeifaddrs(addrs)
        return (received, sent)
    }
}
