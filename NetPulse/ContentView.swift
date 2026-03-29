//
//  ContentView.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/29/26.
//
import SwiftUI

struct ContentView: View {
    
    @StateObject var monitor = NetworkSpeedMonitor()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 30))
            
            Text("Live Network Speed")
                .font(.headline)
            
            Text("\(Int(monitor.downloadSpeed)) KB/s")
                .font(.system(size: 36, weight: .bold))
            
            HStack {
                Text("↓ \(Int(monitor.downloadSpeed)) KB/s")
                Text("↑ \(Int(monitor.uploadSpeed)) KB/s")
            }
        }
        .padding()
        .frame(width: 300, height: 180)
    }
}

#Preview {
    ContentView()
}
