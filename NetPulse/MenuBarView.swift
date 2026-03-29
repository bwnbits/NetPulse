//
//  MenuBarView.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/29/26.
//
import SwiftUI

struct MenuBarView: View {
    
    @ObservedObject var monitor: NetworkSpeedMonitor
    
    var body: some View {
        Text("\(menuFormat(monitor.downloadSpeed))↓ \(menuFormat(monitor.uploadSpeed))↑")
            .font(.system(size: 12, weight: .medium))
    }
}

// MARK: - Compact Formatter (Menu Bar)

func menuFormat(_ speed: Double) -> String {
    if speed < 1 {
        let kb = speed * 1024
        return "\(Int(kb))K"
    } else {
        return String(format: "%.1fM", speed)
    }
}
