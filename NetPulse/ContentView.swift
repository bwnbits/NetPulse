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
            
            // Title
            Text("NetPulse")
                .font(.headline)
            
            // BIG SPEED
            Text(monitor.formatSpeed(monitor.downloadSpeed))
                .font(.system(size: 32, weight: .bold))
            
            // UP / DOWN
            HStack(spacing: 12) {
                Text("↓ \(monitor.formatSpeed(monitor.downloadSpeed))")
                Text("↑ \(monitor.formatSpeed(monitor.uploadSpeed))")
            }
            .font(.system(size: 13))
            
            Divider()
            
            // TOTALS + NETWORK
            VStack(alignment: .leading, spacing: 6) {
                Text("Total Download: \(monitor.formatData(monitor.totalDownload))")
                Text("Total Upload: \(monitor.formatData(monitor.totalUpload))")
                Text("Network: \(monitor.networkType)")
            }
            .font(.system(size: 12))
            
            Divider()
            
            // SPEED TEST SECTION
            VStack(spacing: 6) {
                
                if monitor.isTestingSpeed {
                    Text("Testing speed...")
                        .font(.system(size: 12))
                    
                } else if monitor.maxDownloadMbps == 0 && monitor.maxUploadMbps == 0 {
                    
                    Text("No test run yet")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                } else {
                    
                    Text("Max Download: \(String(format: "%.1f", monitor.maxDownloadMbps)) Mbps")
                    Text("Max Upload: \(String(format: "%.1f", monitor.maxUploadMbps)) Mbps")
                }
                
                Button("Run Speed Test") {
                    monitor.runSpeedTest()
                }
                .font(.system(size: 12))
            }
            
            Divider()
            
            // CONTROLS
            HStack {
                Toggle("Monitoring", isOn: $monitor.isMonitoring)
                
                Spacer()
                
                Button("Reset") {
                    monitor.resetTotals()
                }
            }
        }
        .padding()
        .frame(width: 280, height: 260) // slightly increased
    }
}
