//
//  SpeedTestManager.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/7/26.
//
import Foundation

class SpeedTestManager: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    private var startTime: Date?
    private var receivedBytes: Int64 = 0
    private var sentBytes: Int64 = 0
    
    private var completion: ((Double, Double) -> Void)?
    
    private var taskCompletion: (() -> Void)?
    private var uploadCompletion: (() -> Void)?
    
    // MARK: - START TEST
    
    func startTest(completion: @escaping (Double, Double) -> Void) {
        self.completion = completion
        
        runDownloadTest { download in
            self.runUploadTest { upload in
                DispatchQueue.main.async {
                    completion(download, upload)
                }
            }
        }
    }
    
    // MARK: - DOWNLOAD TEST
    
    private func runDownloadTest(completion: @escaping (Double) -> Void) {
        startTime = Date()
        receivedBytes = 0
        
        // ✅ Primary + fallback URLs
        let urls = [
            "https://proof.ovh.net/files/100Mb.dat",
            "https://speed.cloudflare.com/__down?bytes=100000000",
            "https://download.thinkbroadband.com/100MB.zip"
        ]
        
        startDownload(from: urls, index: 0, completion: completion)
    }
    
    private func startDownload(from urls: [String], index: Int, completion: @escaping (Double) -> Void) {
        
        if index >= urls.count {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        
        guard let url = URL(string: urls[index]) else {
            startDownload(from: urls, index: index + 1, completion: completion)
            return
        }
        
        print("⬇️ Trying:", url.absoluteString)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        
        task.resume()
        
        taskCompletion = { [weak self] in
            guard let self = self else { return }
            
            let duration = Date().timeIntervalSince(self.startTime ?? Date())
            
            if self.receivedBytes == 0 {
                print("⚠️ Download failed, trying fallback...")
                self.startDownload(from: urls, index: index + 1, completion: completion)
                return
            }
            
            let mbps = (Double(self.receivedBytes) * 8) / duration / 1_000_000
            
            DispatchQueue.main.async {
                completion(mbps)
            }
        }
    }
    
    // MARK: - UPLOAD TEST
    
    private func runUploadTest(completion: @escaping (Double) -> Void) {
        startTime = Date()
        sentBytes = 0
        
        let urls = [
            "https://httpbin.org/post",
            "https://postman-echo.com/post"
        ]
        
        startUpload(to: urls, index: 0, completion: completion)
    }
    
    private func startUpload(to urls: [String], index: Int, completion: @escaping (Double) -> Void) {
        
        if index >= urls.count {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        
        guard let url = URL(string: urls[index]) else {
            startUpload(to: urls, index: index + 1, completion: completion)
            return
        }
        
        print("⬆️ Trying:", url.absoluteString)
        
        let data = Data(count: 5 * 1024 * 1024) // 5MB
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.uploadTask(with: request, from: data)
        
        task.resume()
        
        uploadCompletion = { [weak self] in
            guard let self = self else { return }
            
            let duration = Date().timeIntervalSince(self.startTime ?? Date())
            
            if self.sentBytes == 0 {
                print("⚠️ Upload failed, trying fallback...")
                self.startUpload(to: urls, index: index + 1, completion: completion)
                return
            }
            
            let mbps = (Double(self.sentBytes) * 8) / duration / 1_000_000
            
            DispatchQueue.main.async {
                completion(mbps)
            }
        }
    }
    
    // MARK: - DELEGATES
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedBytes += Int64(data.count)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        
        sentBytes = totalBytesSent
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        
        if let error = error {
            print("❌ Error:", error.localizedDescription)
        }
        
        if task is URLSessionUploadTask {
            uploadCompletion?()
        } else {
            taskCompletion?()
        }
    }
}
