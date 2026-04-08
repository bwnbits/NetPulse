// MainWindowView.swift
// NetPulse
// Full main window — shown when user opens the app from Dock / Spotlight.
// Displays live speed, session stats, and speed test in an Apple-style card layout.
// MainWindowView.swift
// NetPulse
// Full main window — shown when user opens the app from Dock / Spotlight.
// Displays live speed, session stats, and speed test in an Apple-style card layout.

import SwiftUI

struct MainWindowView: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor
    @State private var selectedTab: Tab = .live

    enum Tab: String, CaseIterable {
        case live   = "Live"
        case test   = "Speed Test"
        case about  = "About"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Title Bar ──────────────────────────────────────────
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                    Text("NetPulse")
                        .font(.title2.bold())
                }
                Spacer()
                LiveBadge(isOn: monitor.isMonitoring)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // ── Tab Picker ─────────────────────────────────────────
            Picker("Tab", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 28)
            .padding(.bottom, 20)

            Divider()

            // ── Tab Content ────────────────────────────────────────
            Group {
                switch selectedTab {
                case .live:   LiveTab()
                case .test:   SpeedTestTab()
                case .about:  AboutTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(monitor)

        }
        .frame(width: 460, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Live Tab

private struct LiveTab: View {
    @EnvironmentObject var monitor: NetworkSpeedMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                HStack(spacing: 12) {
                    BigSpeedCard(
                        label: "Download",
                        systemImage: "arrow.down.circle.fill",
                        color: .green,
                        value: monitor.formatSpeed(monitor.downloadSpeed)
                    )
                    BigSpeedCard(
                        label: "Upload",
                        systemImage: "arrow.up.circle.fill",
                        color: .blue,
                        value: monitor.formatSpeed(monitor.uploadSpeed)
                    )
                }

                GroupBox(label: Label("Session Totals", systemImage: "chart.bar.fill").font(.subheadline)) {
                    HStack {
                        SessionStat(label: "Downloaded", value: monitor.formatData(monitor.totalDownload), color: .green)
                        Divider().frame(height: 36)
                        SessionStat(label: "Uploaded",   value: monitor.formatData(monitor.totalUpload),   color: .blue)
                        Divider().frame(height: 36)
                        SessionStat(label: "Interface",  value: monitor.networkType,                       color: .orange)
                    }
                    .padding(.top, 4)
                }

                HStack {
                    Toggle("Live Monitoring", isOn: $monitor.isMonitoring)
                        .toggleStyle(.switch)
                    Spacer()
                    Button("Reset Totals") { monitor.resetTotals() }
                        .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Speed Test Tab

private struct SpeedTestTab: View {
    @EnvironmentObject var monitor: NetworkSpeedMonitor

    var body: some View {
        VStack(spacing: 20) {

            GroupBox(label: Label("Test Results", systemImage: "speedometer").font(.subheadline)) {
                if monitor.isTestingSpeed {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.linear)
                        Text("Running speed test… please wait.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                } else {
                    HStack(spacing: 0) {
                        ResultMetric(
                            icon: "arrow.down.circle.fill",
                            iconColor: .green,
                            label: "Download",
                            value: monitor.testDownloadMbps > 0
                                ? String(format: "%.2f Mbps", monitor.testDownloadMbps)
                                : "—"
                        )
                        Divider().frame(height: 60)
                        ResultMetric(
                            icon: "arrow.up.circle.fill",
                            iconColor: .blue,
                            label: "Upload",
                            value: monitor.testUploadMbps > 0
                                ? String(format: "%.2f Mbps", monitor.testUploadMbps)
                                : "—"
                        )
                        Divider().frame(height: 60)
                        ResultMetric(
                            icon: "antenna.radiowaves.left.and.right",
                            iconColor: .orange,
                            label: "Ping",
                            value: monitor.testPingMs > 0
                                ? "\(monitor.testPingMs) ms"
                                : "—"
                        )
                    }
                    .padding(.top, 8)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Data usage is ~720 MB per test (6×100 MB download + 6×20 MB upload). Test takes ~15–75 seconds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: { monitor.runSpeedTest() }) {
                Label(
                    monitor.isTestingSpeed ? "Testing…" : "Run Speed Test",
                    systemImage: "speedometer"
                )
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(monitor.isTestingSpeed)
            .padding(.horizontal)
        }
        .padding(24)
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow, .primary)

            VStack(spacing: 6) {
                Text("NetPulse")
                    .font(.title.bold())
                Text("Version 1.0")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Text("A lightweight macOS menu-bar app that monitors your real-time network speed and runs speed tests — with minimal CPU usage and no data drain.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            // ── Made with love in India ─────────────────────────────
            HStack(spacing: 6) {
                Text("🇮🇳")
                    .font(.title3)
                Text("Made with ❤️ in India")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)

            // ── GitHub link ─────────────────────────────────────────
            Link(destination: URL(string: "https://github.com/bwnbits")!) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                    Text("github.com/bwnbits")
                }
                .font(.callout)
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Reusable Components

private struct BigSpeedCard: View {
    let label:       String
    let systemImage: String
    let color:       Color
    let value:       String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct SessionStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ResultMetric: View {
    let icon:      String
    let iconColor: Color
    let label:     String
    let value:     String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct LiveBadge: View {
    let isOn: Bool
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isOn ? Color.green : Color.gray)
                .frame(width: 7, height: 7)
            Text(isOn ? "Live" : "Paused")
                .font(.caption.weight(.medium))
                .foregroundColor(isOn ? .green : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((isOn ? Color.green : Color.gray).opacity(0.12))
        .clipShape(Capsule())
    }
}
