// ContentView.swift
// NetPulse
//
// Menu-bar popover panel.
// Shows: live speed (prominent) → session totals → speed test results → controls.

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            HStack {
                Label("NetPulse", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Circle()
                    .fill(monitor.isMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(monitor.isMonitoring ? "Live" : "Paused")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // ── Live Speed ───────────────────────────────────────────
            VStack(spacing: 4) {
                Text("Live Network Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    SpeedTile(
                        label: "Download",
                        icon: "arrow.down.circle.fill",
                        iconColor: .green,
                        value: monitor.formatSpeed(monitor.downloadSpeed)
                    )
                    SpeedTile(
                        label: "Upload",
                        icon: "arrow.up.circle.fill",
                        iconColor: .blue,
                        value: monitor.formatSpeed(monitor.uploadSpeed)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── Session Totals ───────────────────────────────────────
            VStack(spacing: 4) {
                Text("Session Totals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    StatRow(label: "Downloaded", value: monitor.formatData(monitor.totalDownload), color: .green)
                    Spacer()
                    StatRow(label: "Uploaded",   value: monitor.formatData(monitor.totalUpload),   color: .blue)
                    Spacer()
                    StatRow(label: "Interface",  value: monitor.networkType, color: .orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── Speed Test ───────────────────────────────────────────
            VStack(spacing: 8) {
                Text("Speed Test")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if monitor.isTestingSpeed {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                        Text("Running test, please wait…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 16) {
                        TestResultTile(label: "↓ DL", value: monitor.testDownloadMbps)
                        TestResultTile(label: "↑ UL", value: monitor.testUploadMbps)
                        VStack(spacing: 2) {
                            Text("Ping")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(monitor.testPingMs > 0 ? "\(monitor.testPingMs) ms" : "—")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(pingColor(monitor.testPingMs))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Button(action: { monitor.runSpeedTest() }) {
                    Label(
                        monitor.isTestingSpeed ? "Testing…" : "Run Speed Test",
                        systemImage: "speedometer"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(monitor.isTestingSpeed)
                .tint(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── Controls ─────────────────────────────────────────────
            HStack {
                Toggle(isOn: $monitor.isMonitoring) {
                    Text("Monitor")
                        .font(.caption)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                Spacer()

                Button("Reset Totals") {
                    monitor.resetTotals()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pingColor(_ ms: Int) -> Color {
        if ms == 0    { return .secondary }
        if ms < 50    { return .green }
        if ms < 150   { return .orange }
        return .red
    }
}

// MARK: - Sub-components

private struct SpeedTile: View {
    let label:     String
    let icon:      String
    let iconColor: Color
    let value:     String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

private struct TestResultTile: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value > 0 ? String(format: "%.1f", value) : "—")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
            Text("Mbps")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
