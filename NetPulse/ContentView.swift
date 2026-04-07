//
//  ContentView.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/29/26.
//
import SwiftUI

struct ContentView: View {
    
    @ObservedObject var monitor: NetworkSpeedMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text("NetPulse").font(.headline)
            
            Text(monitor.formatSpeed(monitor.downloadSpeed))
                .font(.system(size: 32, weight: .bold))
            
            HStack {
                Text("↓ \(monitor.formatSpeed(monitor.downloadSpeed))")
                Text("↑ \(monitor.formatSpeed(monitor.uploadSpeed))")
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Total Download: \(monitor.formatData(monitor.totalDownload))")
                Text("Total Upload: \(monitor.formatData(monitor.totalUpload))")
                Text("Network: \(monitor.networkType)")
            }
            
            Divider()
            
            if monitor.isTestingSpeed {
                Text("Testing speed...")
            } else {
                Text("Max Download: \(String(format: "%.1f", monitor.maxDownloadMbps)) Mbps")
                Text("Max Upload: \(String(format: "%.1f", monitor.maxUploadMbps)) Mbps")
            }
            
            Button("Run Speed Test") {
                monitor.runSpeedTest()
            }
            
            Divider()
            
            HStack {
                Toggle("Monitoring", isOn: $monitor.isMonitoring)
                Spacer()
                Button("Reset") {
                    monitor.resetTotals()
                }
            }
        }
        .padding()
        .frame(width: 280)
    }
}
