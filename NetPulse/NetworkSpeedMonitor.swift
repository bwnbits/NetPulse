// NetworkSpeedMonitor.swift
// NetPulse
//
// Real-time network speed monitoring using getifaddrs (system-level).
// No random values. No fake data.
import Foundation
import Combine
import Darwin

@MainActor
class NetworkSpeedMonitor: ObservableObject {

    // MARK: - Live Speed (updated every second)
    @Published var downloadSpeed: Double = 0   // MB/s
    @Published var uploadSpeed: Double = 0     // MB/s

    // MARK: - Session Totals (PERSISTED)
    @Published var totalDownload: Double = 0   // KB cumulative
    @Published var totalUpload: Double = 0     // KB cumulative

    // MARK: - Network Info
    @Published var networkType: String = "Ethernet"
    @Published var isMonitoring: Bool = true

    // MARK: - Speed Test Results
    @Published var testDownloadMbps: Double = 0
    @Published var testUploadMbps: Double = 0
    @Published var testPingMs: Int = 0
    @Published var isTestingSpeed: Bool = false

    // MARK: - Private
    private var timer: Timer?
    private var prevBytesIn: UInt64 = 0
    private var prevBytesOut: UInt64 = 0
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Persistence Keys
    private let downloadKey = "netpulse_total_download"
    private let uploadKey   = "netpulse_total_upload"

    // MARK: - Init
    init() {
        let (bytesIn, bytesOut) = Self.readNetworkBytes()
        prevBytesIn  = bytesIn
        prevBytesOut = bytesOut

        loadTotals() // ✅ LOAD SAVED DATA

        startMonitoring()
        observeSpeedTestManager()
    }

    // MARK: - Start / Stop Monitoring

    func startMonitoring() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, self.isMonitoring else { return }
            Task { @MainActor in self.tick() }
        }

        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Per-second Tick

    private func tick() {
        let (bytesIn, bytesOut) = Self.readNetworkBytes()

        let deltaIn  = bytesIn  >= prevBytesIn  ? bytesIn  - prevBytesIn  : 0
        let deltaOut = bytesOut >= prevBytesOut ? bytesOut - prevBytesOut : 0

        prevBytesIn  = bytesIn
        prevBytesOut = bytesOut

        // Convert bytes → MB/s
        let downMBs = Double(deltaIn)  / 1_048_576
        let upMBs   = Double(deltaOut) / 1_048_576

        downloadSpeed = downMBs
        uploadSpeed   = upMBs

        // Accumulate totals (KB)
        totalDownload += Double(deltaIn)  / 1_024
        totalUpload   += Double(deltaOut) / 1_024

        // Save persistently
        saveTotals()

        networkType = Self.activeInterface()
    }

    // MARK: - Persistence

    private func saveTotals() {
        UserDefaults.standard.set(totalDownload, forKey: downloadKey)
        UserDefaults.standard.set(totalUpload,   forKey: uploadKey)
    }

    private func loadTotals() {
        totalDownload = UserDefaults.standard.double(forKey: downloadKey)
        totalUpload   = UserDefaults.standard.double(forKey: uploadKey)
    }

    // MARK: - Reset

    func resetTotals() {
        totalDownload = 0
        totalUpload   = 0

        UserDefaults.standard.removeObject(forKey: downloadKey)
        UserDefaults.standard.removeObject(forKey: uploadKey)
    }

    // MARK: - Observe SpeedTestManager

    private func observeSpeedTestManager() {
        let mgr = SpeedTestManager.shared

        mgr.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                guard let self else { return }

                if !running && self.isTestingSpeed {
                    self.testDownloadMbps = mgr.download
                    self.testUploadMbps   = mgr.upload
                    self.testPingMs       = mgr.ping
                    self.isTestingSpeed   = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Run Speed Test

    func runSpeedTest() {
        guard !isTestingSpeed else { return }

        isTestingSpeed = true

        testDownloadMbps = 0
        testUploadMbps   = 0
        testPingMs       = 0

        SpeedTestManager.shared.startTest()
    }

    // MARK: - Format Helpers

    func formatSpeed(_ mbPerSec: Double) -> String {
        let kbPerSec = mbPerSec * 1024

        if kbPerSec < 1 {
            return "0 KB/s"
        } else if kbPerSec < 1024 {
            return String(format: "%.0f KB/s", kbPerSec)
        } else {
            return String(format: "%.2f MB/s", mbPerSec)
        }
    }

    func formatData(_ kb: Double) -> String {
        if kb > 1_048_576 {
            return String(format: "%.2f GB", kb / 1_048_576)
        } else if kb > 1024 {
            return String(format: "%.2f MB", kb / 1024)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }

    // MARK: - System Network Bytes

    static func readNetworkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var bytesIn:  UInt64 = 0
        var bytesOut: UInt64 = 0

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let start = ifaddrPtr else {
            return (0, 0)
        }
        defer { freeifaddrs(start) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = start

        while let iface = cursor {
            let flags = Int32(iface.pointee.ifa_flags)

            let isUp       = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && !isLoopback,
               iface.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let data = iface.pointee.ifa_data {

                let ifdata = data.assumingMemoryBound(to: if_data.self).pointee
                bytesIn  += UInt64(ifdata.ifi_ibytes)
                bytesOut += UInt64(ifdata.ifi_obytes)
            }

            cursor = iface.pointee.ifa_next
        }

        return (bytesIn, bytesOut)
    }

    static func activeInterface() -> String {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let start = ifaddrPtr else {
            return "Unknown"
        }
        defer { freeifaddrs(start) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = start

        while let iface = cursor {
            let flags = Int32(iface.pointee.ifa_flags)

            if (flags & IFF_UP) != 0,
               (flags & IFF_LOOPBACK) == 0,
               iface.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {

                let name = String(cString: iface.pointee.ifa_name)

                if name.hasPrefix("en0") { return "Wi-Fi" }
                if name.hasPrefix("en1") { return "Ethernet" }
                if name.hasPrefix("utun") { return "VPN" }
            }

            cursor = iface.pointee.ifa_next
        }

        return "Ethernet-github/bwnbits"
    }
}
