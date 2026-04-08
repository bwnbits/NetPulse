// SpeedTestManager.swift
// NetPulse

import Foundation
import Combine

class SpeedTestManager: NSObject, ObservableObject {

    static let shared = SpeedTestManager()
    private override init() {}

    // MARK: - Published

    @Published var download: Double  = 0    // Mbps
    @Published var upload: Double    = 0    // Mbps
    @Published var ping: Int         = 0    // ms
    @Published var isRunning: Bool   = false

    // MARK: - Private state

    private var startTime: Date       = Date()
    private var receivedBytes: Int64  = 0
    private var sentBytes: Int64      = 0
    private let bytesLock             = NSLock()

    // Parallel stream count — key to saturating high-speed connections
    private let parallelStreams       = 6

    // Per-stream limits
    private let downloadDuration: TimeInterval = 15   // 15s test window
    private let uploadSize: Int       = 20 * 1024 * 1024   // 20 MB per stream

    private var downloadTasks: [URLSessionDataTask] = []
    private var downloadSessions: [URLSession]      = []
    private var uploadSessions: [URLSession]        = []

    private var downloadCompletion: ((Double) -> Void)?
    private var uploadCompletion:   ((Double) -> Void)?
    private var downloadTimerFired  = false
    private var activeUploadCount   = 0
    private var uploadBytesMap: [ObjectIdentifier: Int64] = [:]

    // Fast CDN files — large enough to sustain throughput
    // We cycle through multiple URLs across parallel streams
    private let downloadURLs = [
        "https://proof.ovh.net/files/100Mb.dat",
        "https://proof.ovh.net/files/100Mb.dat",
        "https://proof.ovh.net/files/100Mb.dat",
        "https://speed.hetzner.de/100MB.bin",
        "https://speed.hetzner.de/100MB.bin",
        "https://proof.ovh.net/files/100Mb.dat",
    ]

    // MARK: - Public

    func startTest() {
        guard !isRunning else { return }

        DispatchQueue.main.async { self.isRunning = true }

        download = 0
        upload   = 0
        ping     = measurePing()

        runDownloadTest { [weak self] mbps in
            guard let self else { return }

            DispatchQueue.main.async {
                self.download = mbps
            }

            self.runUploadTest { uploadMbps in
                DispatchQueue.main.async {
                    self.upload    = uploadMbps
                    self.isRunning = false
                }
            }
        }
    }

    // MARK: - Ping

    private func measurePing() -> Int {
        // Average 3 pings for accuracy
        var times: [Int] = []

        for _ in 0..<3 {
            let sem = DispatchSemaphore(value: 0)
            let start = Date()

            var req = URLRequest(url: URL(string: "https://www.google.com")!)
            req.timeoutInterval = 5

            URLSession.shared.dataTask(with: req) { _, _, _ in
                times.append(Int(Date().timeIntervalSince(start) * 1000))
                sem.signal()
            }.resume()

            sem.wait()
        }

        return times.min() ?? 0   // report best ping
    }

    // MARK: - Download (parallel streams)

    private func runDownloadTest(completion: @escaping (Double) -> Void) {
        bytesLock.lock()
        receivedBytes   = 0
        bytesLock.unlock()

        startTime           = Date()
        downloadTimerFired  = false
        downloadCompletion  = completion
        downloadTasks       = []
        downloadSessions    = []

        // Warm-up: discard first 2 seconds from measurement
        let warmupDuration: TimeInterval = 2.0

        for i in 0..<parallelStreams {
            guard let url = URL(string: downloadURLs[i % downloadURLs.count]) else { continue }

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest  = downloadDuration + 5
            config.timeoutIntervalForResource = downloadDuration + 5
            // Allow more simultaneous connections per host
            config.httpMaximumConnectionsPerHost = parallelStreams

            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            downloadSessions.append(session)

            let task = session.dataTask(with: url)
            downloadTasks.append(task)
            task.resume()
        }

        // Stop after downloadDuration seconds, measure only after warm-up
        DispatchQueue.global().asyncAfter(deadline: .now() + downloadDuration) { [weak self] in
            self?.finishDownload(warmup: warmupDuration)
        }
    }

    private func finishDownload(warmup: TimeInterval = 0) {
        guard !downloadTimerFired else { return }
        downloadTimerFired = true

        downloadTasks.forEach { $0.cancel() }
        downloadTasks    = []

        bytesLock.lock()
        let bytes = receivedBytes
        bytesLock.unlock()

        // Effective duration = total - warmup (bytes accumulated from t=0,
        // but speed is only meaningful after TCP ramp-up)
        let totalDuration = Date().timeIntervalSince(startTime)
        let effectiveDuration = max(totalDuration - warmup, 1.0)

        // Estimate bytes transferred after warm-up (proportional approximation)
        let warmupFraction = warmup / max(totalDuration, 0.001)
        let effectiveBytes = Double(bytes) * (1.0 - warmupFraction)

        let mbps = (effectiveBytes * 8) / effectiveDuration / 1_000_000

        let cb = downloadCompletion
        downloadCompletion = nil
        DispatchQueue.main.async { cb?(mbps) }
    }

    // MARK: - Upload (parallel streams)

    private func runUploadTest(completion: @escaping (Double) -> Void) {
        bytesLock.lock()
        sentBytes     = 0
        uploadBytesMap = [:]
        bytesLock.unlock()

        startTime         = Date()
        uploadCompletion  = completion
        uploadSessions    = []
        activeUploadCount = parallelStreams

        // Random data payload per stream
        let data = Data(count: uploadSize)

        for _ in 0..<parallelStreams {
            guard let url = URL(string: "https://httpbin.org/post") else {
                activeUploadCount -= 1
                continue
            }

            var req = URLRequest(url: url)
            req.httpMethod      = "POST"
            req.timeoutInterval = 60

            let config = URLSessionConfiguration.ephemeral
            config.httpMaximumConnectionsPerHost = parallelStreams
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            uploadSessions.append(session)

            session.uploadTask(with: req, from: data).resume()
        }

        // Safety timeout for upload
        DispatchQueue.global().asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.finishUploadIfNeeded()
        }
    }

    private func finishUploadIfNeeded() {
        let cb = uploadCompletion
        guard cb != nil else { return }
        uploadCompletion = nil

        bytesLock.lock()
        let bytes = sentBytes
        bytesLock.unlock()

        let duration = max(Date().timeIntervalSince(startTime), 0.001)
        let mbps = (Double(bytes) * 8) / duration / 1_000_000
        DispatchQueue.main.async { cb?(mbps) }
    }
}

// MARK: - Delegates

extension SpeedTestManager: URLSessionDataDelegate, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        bytesLock.lock()
        receivedBytes += Int64(data.count)
        bytesLock.unlock()
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {

        bytesLock.lock()
        let key = ObjectIdentifier(task)
        let prev = uploadBytesMap[key] ?? 0
        uploadBytesMap[key] = totalBytesSent
        sentBytes += (totalBytesSent - prev)
        bytesLock.unlock()
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {

        if task is URLSessionUploadTask {

            bytesLock.lock()
            activeUploadCount -= 1
            let remaining = activeUploadCount
            bytesLock.unlock()

            if remaining <= 0 {
                finishUploadIfNeeded()
            }

        } else {
            // Download task completed early (file finished before timer)
            // Do nothing — timer will fire and collect bytes
        }
    }
}
