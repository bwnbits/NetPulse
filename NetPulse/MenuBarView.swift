// MenuBarView.swift
// NetPulse
//
// Shows live download ↓ and upload ↑ in the menu bar label.
// Uses real MB/s values from NetworkSpeedMonitor (not test results).

import SwiftUI

struct MenuBarView: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .imageScale(.small)
            Text(shortSpeed(monitor.downloadSpeed))
                .monospacedDigit()

            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.blue)
                .imageScale(.small)
            Text(shortSpeed(monitor.uploadSpeed))
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium))
    }

    /// Compact format: "12.3M" or "512K"
    private func shortSpeed(_ mbPerSec: Double) -> String {
        let kb = mbPerSec * 1024
        if kb < 1    { return "0K" }
        if kb < 1024 { return String(format: "%.0fK", kb) }
        return String(format: "%.1fM", mbPerSec)
    }
}
