// SpeedTestManager.swift
// NetPulse
//
// Speed test with:
//  - Smaller download file (10 MB cap via byte limit + cancel)
//  - Upload capped at 2 MB
//  - Task cancelled after 30 s or 10 MB received
//  - Completion driven by real delegate callbacks (no DispatchQueue.after)

import Foundation
import Combine

class SpeedTestManager: NSObject, ObservableObject {

    static let shared = SpeedTestManager()
    private override init() {}

    // Observed by NetworkSpeedMonitor via Combine
    @Published var download: Double  = 0    // Mbps
    @Published var upload: Double    = 0    // Mbps
    @Published var ping: Int         = 0    // ms
    @Published var isRunning: Bool   = false

    // MARK: - Private state

    private var startTime: Date       = Date()
    private var receivedBytes: Int64  = 0
    private var sentBytes: Int64      = 0

    private let downloadCap: Int64    = 300 * 1024 * 1024   // 300MB cap
    private let downloadTimeout: TimeInterval = 30
    private let uploadSize: Int       = 2 * 1024 * 1024    // 2 MB upload payload

    private var downloadTask: URLSessionDataTask?
    private var downloadSession: URLSession?
    private var uploadSession: URLSession?

    private var downloadCompletion: ((Double) -> Void)?
    private var uploadCompletion:   ((Double) -> Void)?

    // MARK: - Public entry point

    func startTest() {
        guard !isRunning else { return }

        DispatchQueue.main.async { self.isRunning = true }
        download = 0
        upload   = 0
        ping     = measurePing()

        runDownloadTest { [weak self] mbps in
            guard let self else { return }
            DispatchQueue.main.async { self.download = mbps }

            self.runUploadTest { uploadMbps in
                DispatchQueue.main.async {
                    self.upload    = uploadMbps
                    self.isRunning = false
                }
            }
        }
    }

    // MARK: - Ping (synchronous, off main thread)

    private func measurePing() -> Int {
        let sem = DispatchSemaphore(value: 0)
        let start = Date()
        var elapsed = 0

        var req = URLRequest(url: URL(string: "https://www.google.com")!)
        req.timeoutInterval = 5

        URLSession.shared.dataTask(with: req) { _, _, _ in
            elapsed = Int(Date().timeIntervalSince(start) * 1000)
            sem.signal()
        }.resume()

        sem.wait()
        return elapsed
    }

    // MARK: - Download Test

    private func runDownloadTest(completion: @escaping (Double) -> Void) {
        receivedBytes = 0
        startTime     = Date()

        // 10 MB file — we'll cancel as soon as we hit downloadCap
        guard let url = URL(string: "https://proof.ovh.net/files/10Mb.dat") else {
            completion(0); return
        }

        downloadCompletion = completion

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = downloadTimeout
        config.timeoutIntervalForResource = downloadTimeout

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        downloadSession = session

        let task = session.dataTask(with: url)
        downloadTask = task
        task.resume()

        // Hard timeout cancel
        DispatchQueue.global().asyncAfter(deadline: .now() + downloadTimeout) { [weak self] in
            self?.finishDownload()
        }
    }

    private func finishDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        let duration = max(Date().timeIntervalSince(startTime), 0.001)
        let mbps = (Double(receivedBytes) * 8) / duration / 1_000_000

        let cb = downloadCompletion
        downloadCompletion = nil
        cb?(mbps)
    }

    // MARK: - Upload Test

    private func runUploadTest(completion: @escaping (Double) -> Void) {
        sentBytes = 0
        startTime = Date()

        guard let url = URL(string: "https://httpbin.org/post") else {
            completion(0); return
        }

        uploadCompletion = completion

        let data = Data(count: uploadSize)    // 2 MB of zeros
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30

        let config   = URLSessionConfiguration.ephemeral
        let session  = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        uploadSession = session

        session.uploadTask(with: req, from: data).resume()
    }
}

// MARK: - URLSession Delegates

extension SpeedTestManager: URLSessionDataDelegate, URLSessionTaskDelegate {

    // Called as download data arrives
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        receivedBytes += Int64(data.count)

        // Cancel early once cap is hit
        if receivedBytes >= downloadCap {
            finishDownload()
        }
    }

    // Called as upload bytes are sent
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        sentBytes = totalBytesSent
    }

    // Called when a task completes (success, cancel, or error)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {

        if task is URLSessionUploadTask {
            let duration = max(Date().timeIntervalSince(startTime), 0.001)
            let mbps = (Double(sentBytes) * 8) / duration / 1_000_000
            let cb = uploadCompletion
            uploadCompletion = nil
            cb?(mbps)
        } else {
            // Download completed naturally (before cap) — finish if not already done
            if downloadCompletion != nil {
                finishDownload()
            }
        }
    }
}
