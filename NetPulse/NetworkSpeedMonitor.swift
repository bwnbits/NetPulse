import Foundation
import Combine

@MainActor
class NetworkSpeedMonitor: ObservableObject {
    
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var totalDownload: Double = 0
    @Published var totalUpload: Double = 0
    @Published var networkType: String = "Unknown"
    @Published var isMonitoring: Bool = true
    
    @Published var maxDownloadMbps: Double = 0
    @Published var maxUploadMbps: Double = 0
    @Published var isTestingSpeed: Bool = false
    
    private var lastReceived: UInt64 = 0
    private var lastSent: UInt64 = 0
    private var timer: Timer?
    
    private var jsonURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NetPulse", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        return folder.appendingPathComponent("speed.json")
    }
    
    // MARK: - SPEED TEST
    
    func runSpeedTest() {
        if isTestingSpeed { return }
        
        isTestingSpeed = true
        
        let tester = SpeedTestManager()
        
        tester.startTest { download, upload in
            self.maxDownloadMbps = download
            self.maxUploadMbps = upload
            self.isTestingSpeed = false
            
            let result: [String: Any] = [
                "download": download,
                "upload": upload
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: result) {
                try? data.write(to: self.jsonURL)
            }
        }
    }
    
    // MARK: - INIT
    
    init() {
        totalDownload = UserDefaults.standard.double(forKey: "totalDownload")
        totalUpload = UserDefaults.standard.double(forKey: "totalUpload")
        
        loadLastResult()
        initializeBaseline()
        startMonitoring()
    }
    
    private func loadLastResult() {
        if let data = try? Data(contentsOf: jsonURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            maxDownloadMbps = json["download"] as? Double ?? 0
            maxUploadMbps = json["upload"] as? Double ?? 0
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateSpeed()
        }
    }
    
    private func updateSpeed() {
        guard isMonitoring else { return }
        
        let data = getNetworkBytes()
        
        let down = data.received - lastReceived
        let up = data.sent - lastSent
        
        lastReceived = data.received
        lastSent = data.sent
        
        let downMB = Double(down) / (1024.0 * 1024.0)
        let upMB = Double(up) / (1024.0 * 1024.0)
        
        self.downloadSpeed = downMB
        self.uploadSpeed = upMB
        
        self.totalDownload += Double(down) / 1024.0
        self.totalUpload += Double(up) / 1024.0
        
        UserDefaults.standard.set(self.totalDownload, forKey: "totalDownload")
        UserDefaults.standard.set(self.totalUpload, forKey: "totalUpload")
        
        self.networkType = detectNetwork()
    }
    
    private func initializeBaseline() {
        let data = getNetworkBytes()
        lastReceived = data.received
        lastSent = data.sent
    }
    
    private func detectNetwork() -> String {
        if isInterfaceActive("en0") { return "WiFi" }
        if isInterfaceActive("en1") { return "Ethernet" }
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
    
    func formatSpeed(_ speed: Double) -> String {
        speed < 1 ? "\(Int(speed * 1024)) KB/s" : String(format: "%.2f MB/s", speed)
    }
    
    func formatData(_ kb: Double) -> String {
        if kb > 1024 * 1024 {
            return String(format: "%.2f GB", kb / (1024 * 1024))
        } else if kb > 1024 {
            return String(format: "%.2f MB", kb / 1024)
        } else {
            return "\(Int(kb)) KB"
        }
    }
    
    func resetTotals() {
        totalDownload = 0
        totalUpload = 0
        
        UserDefaults.standard.set(0, forKey: "totalDownload")
        UserDefaults.standard.set(0, forKey: "totalUpload")
    }
}
