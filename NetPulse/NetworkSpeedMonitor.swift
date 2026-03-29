import Foundation
import Combine

class NetworkSpeedMonitor: ObservableObject {
    
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var totalDownload: Double = 0   // in KB
    @Published var totalUpload: Double = 0     // in KB
    @Published var networkType: String = "Unknown"
    @Published var isMonitoring: Bool = true
    
    private var lastReceived: UInt64 = 0
    private var lastSent: UInt64 = 0
    private var timer: Timer?
    
    // MARK: - INIT (Load saved data)
    
    init() {
        // ✅ Load saved totals
        totalDownload = UserDefaults.standard.double(forKey: "totalDownload")
        totalUpload = UserDefaults.standard.double(forKey: "totalUpload")
        
        initializeBaseline()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Timer
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateSpeed()
        }
    }
    
    // MARK: - Core Logic
    
    private func updateSpeed() {
        guard isMonitoring else { return }
        
        let data = getNetworkBytes()
        
        let down = data.received - lastReceived
        let up = data.sent - lastSent
        
        lastReceived = data.received
        lastSent = data.sent
        
        DispatchQueue.main.async {
            
            // Speed (MB/s)
            let downMB = Double(down) / (1024.0 * 1024.0)
            let upMB = Double(up) / (1024.0 * 1024.0)
            
            self.downloadSpeed = downMB
            self.uploadSpeed = upMB
            
            // ✅ Accumulate totals (KB)
            self.totalDownload += Double(down) / 1024.0
            self.totalUpload += Double(up) / 1024.0
            
            // ✅ SAVE (critical fix)
            UserDefaults.standard.set(self.totalDownload, forKey: "totalDownload")
            UserDefaults.standard.set(self.totalUpload, forKey: "totalUpload")
            
            // Network type
            self.networkType = self.detectNetwork()
        }
    }
    
    // MARK: - Baseline
    
    private func initializeBaseline() {
        let data = getNetworkBytes()
        lastReceived = data.received
        lastSent = data.sent
    }
    
    // MARK: - Network Detection
    
    private func detectNetwork() -> String {
        if isInterfaceActive("en0") {
            return "WiFi"
        } else if isInterfaceActive("en1") {
            return "Ethernet"
        }
        return "Unknown"
    }
    
    private func isInterfaceActive(_ name: String) -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&addrs) == 0 {
            var ptr = addrs
            
            while ptr != nil {
                let interface = ptr!.pointee
                let interfaceName = String(cString: interface.ifa_name)
                
                if interfaceName == name && (interface.ifa_flags & UInt32(IFF_UP)) != 0 {
                    freeifaddrs(addrs)
                    return true
                }
                
                ptr = interface.ifa_next
            }
        }
        
        freeifaddrs(addrs)
        return false
    }
    
    // MARK: - Network Bytes
    
    private func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        var received: UInt64 = 0
        var sent: UInt64 = 0
        
        if getifaddrs(&addrs) == 0 {
            var pointer = addrs
            
            while pointer != nil {
                let interface = pointer!.pointee
                let name = String(cString: interface.ifa_name)
                
                if name.hasPrefix("en") {
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
    
    // MARK: - Formatters
    
    func formatSpeed(_ speed: Double) -> String {
        if speed < 1 {
            return String(format: "%.0f KB/s", speed * 1024)
        } else {
            return String(format: "%.2f MB/s", speed)
        }
    }
    
    func formatData(_ kb: Double) -> String {
        if kb > 1024 * 1024 {
            return String(format: "%.2f GB", kb / (1024 * 1024))
        } else if kb > 1024 {
            return String(format: "%.2f MB", kb / 1024)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }
    
    // MARK: - Controls
    
    func resetTotals() {
        totalDownload = 0
        totalUpload = 0
        
        // ✅ Also clear saved data
        UserDefaults.standard.set(0, forKey: "totalDownload")
        UserDefaults.standard.set(0, forKey: "totalUpload")
    }
}
