// MainWindowView.swift
// NetPulse
// Full main window — shown when user opens the app from Dock / Spotlight.
// Displays live speed, session stats, speed test, and settings in an Apple-style card layout.

import SwiftUI
import AppKit

struct MainWindowView: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor

    @StateObject private var thermalMonitor = ThermalMonitor()

    @State private var selectedTab: Tab = .live

    @AppStorage("showMacThermal")
    private var showMacThermal = true

    @AppStorage("showSpeedTest")
    private var showSpeedTest = true

    enum Tab: String, CaseIterable {
        case live = "Live"
        case test = "Speed Test"
        case settings = "Settings"
        case about = "About"
    }

    private var availableTabs: [Tab] {
        var tabs: [Tab] = [.live]

        if showSpeedTest {
            tabs.append(.test)
        }

        tabs.append(.settings)
        tabs.append(.about)

        return tabs
    }

    var body: some View {

        VStack(spacing: 0) {

            // ─────────────────────────────────────────────
            // HEADER
            // ─────────────────────────────────────────────

            HStack(spacing: 12) {

                ZStack {
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .fill(Color.yellow.opacity(0.14))
                    .frame(width: 38, height: 38)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("NetPulse")
                        .font(.system(size: 17, weight: .bold))

                    Text("Network utility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                LiveBadge(
                    isOn: monitor.isMonitoring
                )
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 14)


            // ─────────────────────────────────────────────
            // TAB BAR
            // ─────────────────────────────────────────────

            HStack(spacing: 4) {

                ForEach(
                    availableTabs,
                    id: \.self
                ) { tab in

                    TabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(
                            .easeInOut(duration: 0.15)
                        ) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(4)
            .background(
                Color.primary.opacity(0.055)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )
            .padding(.horizontal, 22)
            .padding(.bottom, 16)


            Divider()


            // ─────────────────────────────────────────────
            // CONTENT
            // ─────────────────────────────────────────────

            Group {

                switch selectedTab {

                case .live:

                    LiveTab(
                        showMacThermal: showMacThermal
                    )

                case .test:

                    SpeedTestTab()

                case .settings:

                    SettingsTab()

                case .about:

                    AboutTab()
                }
            }
            .environmentObject(monitor)
            .environmentObject(thermalMonitor)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(
            width: 440,
            height: 500
        )
        .background(
            Color(NSColor.windowBackgroundColor)
        )
        .onChange(of: showSpeedTest) { _, enabled in

            if !enabled && selectedTab == .test {
                selectedTab = .live
            }
        }
    }
}


// MARK: - Tab

private extension MainWindowView.Tab {

    var icon: String {

        switch self {

        case .live:
            return "waveform.path.ecg"

        case .test:
            return "speedometer"

        case .settings:
            return "gearshape"

        case .about:
            return "info.circle"
        }
    }
}


// MARK: - Live Tab

private struct LiveTab: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor
    @EnvironmentObject var thermalMonitor: ThermalMonitor

    let showMacThermal: Bool

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                // ─────────────────────────────────────────
                // CURRENT SPEED
                // ─────────────────────────────────────────

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    SectionTitle(
                        title: "Live Network Speed",
                        icon: "waveform.path.ecg"
                    )

                    HStack(spacing: 10) {

                        BigSpeedCard(
                            label: "Download",
                            systemImage:
                                "arrow.down.circle.fill",
                            color: .green,
                            value:
                                monitor.formatSpeed(
                                    monitor.downloadSpeed
                                )
                        )

                        BigSpeedCard(
                            label: "Upload",
                            systemImage:
                                "arrow.up.circle.fill",
                            color: .blue,
                            value:
                                monitor.formatSpeed(
                                    monitor.uploadSpeed
                                )
                        )
                    }
                }


                // ─────────────────────────────────────────
                // SESSION
                // ─────────────────────────────────────────

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    SectionTitle(
                        title: "Session",
                        icon: "chart.bar.fill"
                    )

                    HStack(spacing: 0) {

                        SessionStat(
                            label: "Downloaded",
                            value:
                                monitor.formatData(
                                    monitor.totalDownload
                                ),
                            color: .green
                        )

                        Divider()
                            .frame(height: 34)

                        SessionStat(
                            label: "Uploaded",
                            value:
                                monitor.formatData(
                                    monitor.totalUpload
                                ),
                            color: .blue
                        )

                        Divider()
                            .frame(height: 34)

                        SessionStat(
                            label: "Interface",
                            value:
                                monitor.networkType,
                            color: .orange
                        )
                    }
                    .padding(.vertical, 12)
                    .background(
                        Color.primary.opacity(0.045)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                    )
                }


                // ─────────────────────────────────────────
                // THERMAL
                // ─────────────────────────────────────────

                if showMacThermal {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        SectionTitle(
                            title: "Mac Thermal",
                            icon: "thermometer.medium"
                        )

                        HStack(spacing: 12) {

                            ZStack {

                                Circle()
                                    .fill(
                                        thermalMonitor.color
                                            .opacity(0.12)
                                    )
                                    .frame(
                                        width: 38,
                                        height: 38
                                    )

                                Image(
                                    systemName:
                                        thermalMonitor.icon
                                )
                                .foregroundColor(
                                    thermalMonitor.color
                                )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 2
                            ) {

                                Text(
                                    thermalMonitor.statusText
                                )
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .semibold
                                    )
                                )

                                Text(
                                    "System thermal pressure"
                                )
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            Circle()
                                .fill(
                                    thermalMonitor.color
                                )
                                .frame(
                                    width: 8,
                                    height: 8
                                )
                        }
                        .padding(12)
                        .background(
                            Color.primary.opacity(0.045)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                        )
                    }
                }


                // ─────────────────────────────────────────
                // CONTROLS
                // ─────────────────────────────────────────

                HStack {

                    HStack(spacing: 8) {

                        Image(
                            systemName:
                                "antenna.radiowaves.left.and.right"
                        )
                        .foregroundColor(
                            monitor.isMonitoring
                            ? .green
                            : .secondary
                        )

                        Text("Live Monitoring")
                            .font(
                                .callout.weight(.medium)
                            )
                    }

                    Spacer()

                    Toggle(
                        "",
                        isOn:
                            $monitor.isMonitoring
                    )
                    .toggleStyle(.switch)
                    .labelsHidden()

                    Button("Reset") {

                        monitor.resetTotals()

                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(20)
        }
    }
}


// MARK: - Speed Test Tab

private struct SpeedTestTab: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor

    var body: some View {

        VStack(spacing: 16) {

            SectionTitle(
                title: "Network Speed Test",
                icon: "speedometer"
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )


            // ─────────────────────────────────────────
            // RESULTS CARD
            // ─────────────────────────────────────────

            VStack(spacing: 0) {

                if monitor.isTestingSpeed {

                    VStack(spacing: 12) {

                        ProgressView()
                            .progressViewStyle(
                                .linear
                            )

                        Text(
                            "Running speed test…"
                        )
                        .font(.callout)
                        .foregroundColor(
                            .secondary
                        )

                        Text(
                            "Please wait"
                        )
                        .font(.caption)
                        .foregroundColor(
                            .secondary
                        )
                    }
                    .padding(24)

                } else {

                    HStack(spacing: 0) {

                        ResultMetric(
                            icon:
                                "arrow.down.circle.fill",
                            iconColor: .green,
                            label: "Download",
                            value:
                                monitor.testDownloadMbps > 0
                                ? String(
                                    format:
                                        "%.1f Mbps",
                                    monitor.testDownloadMbps
                                )
                                : "—"
                        )

                        Divider()
                            .frame(height: 70)

                        ResultMetric(
                            icon:
                                "arrow.up.circle.fill",
                            iconColor: .blue,
                            label: "Upload",
                            value:
                                monitor.testUploadMbps > 0
                                ? String(
                                    format:
                                        "%.1f Mbps",
                                    monitor.testUploadMbps
                                )
                                : "—"
                        )

                        Divider()
                            .frame(height: 70)

                        ResultMetric(
                            icon:
                                "antenna.radiowaves.left.and.right",
                            iconColor: .orange,
                            label: "Ping",
                            value:
                                monitor.testPingMs > 0
                                ? "\(monitor.testPingMs) ms"
                                : "—"
                        )
                    }
                    .padding(.vertical, 18)
                }
            }
            .background(
                Color.primary.opacity(0.045)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )


            // ─────────────────────────────────────────
            // INFO
            // ─────────────────────────────────────────

            HStack(
                alignment: .top,
                spacing: 8
            ) {

                Image(
                    systemName: "info.circle"
                )
                .foregroundColor(
                    .secondary
                )

                Text(
                    "A test uses approximately 720 MB of data and may take 15–75 seconds."
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
            }


            Spacer()


            // ─────────────────────────────────────────
            // RUN BUTTON
            // ─────────────────────────────────────────

            Button(
                action: {
                    monitor.runSpeedTest()
                }
            ) {

                Label(
                    monitor.isTestingSpeed
                    ? "Testing…"
                    : "Run Speed Test",
                    systemImage: "speedometer"
                )
                .frame(
                    maxWidth: .infinity
                )
                .font(
                    .headline
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .controlSize(
                .large
            )
            .disabled(
                monitor.isTestingSpeed
            )
        }
        .padding(20)
    }
}


// MARK: - Settings Tab

private struct SettingsTab: View {

    @EnvironmentObject var monitor: NetworkSpeedMonitor

    @AppStorage("showMacThermal")
    private var showMacThermal = true

    @AppStorage("showSpeedTest")
    private var showSpeedTest = true

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            SectionTitle(
                title: "Settings",
                icon: "gearshape"
            )


            VStack(spacing: 0) {

                SettingsRow(
                    title: "Show in Dock",
                    subtitle:
                        "Keep NetPulse visible in the Dock.",
                    isOn:
                        $monitor.showDockIcon
                )

                Divider()

                SettingsRow(
                    title: "Launch at Login",
                    subtitle:
                        "Start NetPulse automatically.",
                    isOn:
                        $monitor.launchAtLogin
                )

                Divider()

                SettingsRow(
                    title: "Show Mac Thermal",
                    subtitle:
                        "Display thermal pressure on the Live tab.",
                    isOn:
                        $showMacThermal
                )

                Divider()

                SettingsRow(
                    title: "Show Speed Test",
                    subtitle:
                        "Show the Speed Test tab and controls.",
                    isOn:
                        $showSpeedTest
                )
            }
            .background(
                Color.primary.opacity(0.045)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )


            Spacer()


            Button(role: .destructive) {

                NSApplication.shared
                    .terminate(nil)

            } label: {

                Label(
                    "Quit NetPulse",
                    systemImage: "power"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
    }
}


// MARK: - Settings Row

private struct SettingsRow: View {

    let title: String
    let subtitle: String

    @Binding var isOn: Bool

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 12
        ) {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(
                        .callout.weight(.medium)
                    )

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(
                        .secondary
                    )
            }

            Spacer()

            Toggle(
                "",
                isOn: $isOn
            )
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(
            .horizontal,
            14
        )
        .padding(
            .vertical,
            11
        )
    }
}


// MARK: - About Tab

private struct AboutTab: View {

    var body: some View {

        VStack(spacing: 14) {

            Spacer()


            // ─────────────────────────────────────────
            // APP ICON
            // ─────────────────────────────────────────

            ZStack {

                Circle()
                    .fill(
                        Color.yellow.opacity(0.12)
                    )
                    .frame(
                        width: 78,
                        height: 78
                    )

                Image(
                    systemName:
                        "bolt.circle.fill"
                )
                .font(
                    .system(size: 50)
                )
                .foregroundColor(
                    .yellow
                )
            }


            // ─────────────────────────────────────────
            // APP NAME / VERSION
            // ─────────────────────────────────────────

            VStack(spacing: 4) {

                Text("NetPulse")
                    .font(
                        .title.bold()
                    )

                Text("Version 4.0.0")
                    .font(.caption)
                    .foregroundColor(
                        .secondary
                    )
            }


            Text(
                "A lightweight macOS network utility for monitoring real-time network speed, session usage, thermal pressure, and network performance."
            )
            .font(.callout)
            .foregroundColor(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )
            .frame(
                maxWidth: 330
            )


            // ─────────────────────────────────────────
            // LINKS
            // ─────────────────────────────────────────

            VStack(spacing: 8) {

                // GitHub

                Link(
                    destination: URL(
                        string:
                            "https://github.com/bwnbits/NetPulse"
                    )!
                ) {

                    AboutLinkRow(
                        icon:
                            "chevron.left.forwardslash.chevron.right",
                        title: "GitHub",
                        subtitle:
                            "View source code and project"
                    )
                }
                .buttonStyle(.plain)


                // Latest Release

                Link(
                    destination: URL(
                        string:
                            "https://github.com/bwnbits/NetPulse/releases"
                    )!
                ) {

                    AboutLinkRow(
                        icon:
                            "arrow.down.circle",
                        title: "Latest Release",
                        subtitle:
                            "Check for new NetPulse versions"
                    )
                }
                .buttonStyle(.plain)


                // Report Issue

                Link(
                    destination: URL(
                        string:
                            "https://github.com/bwnbits/NetPulse/issues"
                    )!
                ) {

                    AboutLinkRow(
                        icon:
                            "exclamationmark.bubble",
                        title: "Report an Issue",
                        subtitle:
                            "Report bugs or suggest improvements"
                    )
                }
                .buttonStyle(.plain)


                // LinkedIn

                Link(
                    destination: URL(
                        string:
                            "https://linkedin.com/in/abhishekruhela"
                    )!
                ) {

                    AboutLinkRow(
                        icon:
                            "person.crop.circle",
                        title: "LinkedIn",
                        subtitle:
                            "linkedin.com/in/abhishekruhela"
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(
                maxWidth: 340
            )


            Spacer()


            // ─────────────────────────────────────────
            // FOOTER
            // ─────────────────────────────────────────

            HStack(spacing: 6) {

                Text("🇮🇳")
                    .font(.title3)

                Text(
                    "Made with ❤️ in India"
                )
                .font(
                    .caption.weight(.medium)
                )
                .foregroundColor(
                    .secondary
                )
            }

            Text("© 2026 bwnbits")
                .font(.caption2)
                .foregroundColor(
                    .secondary.opacity(0.7)
                )
        }
        .padding(22)
    }
}


// MARK: - About Link Row

private struct AboutLinkRow: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(spacing: 12) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(
                    Color.primary.opacity(0.06)
                )
                .frame(
                    width: 34,
                    height: 34
                )

                Image(
                    systemName: icon
                )
                .font(
                    .system(size: 14)
                )
                .foregroundColor(
                    .primary
                )
            }


            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(
                        .callout.weight(.medium)
                    )
                    .foregroundColor(
                        .primary
                    )

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(
                        .secondary
                    )
            }


            Spacer()


            Image(
                systemName: "arrow.up.right"
            )
            .font(.caption)
            .foregroundColor(
                .secondary
            )
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            9
        )
        .background(
            Color.primary.opacity(0.045)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
    }
}


// MARK: - Big Speed Card

private struct BigSpeedCard: View {

    let label: String
    let systemImage: String
    let color: Color
    let value: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(spacing: 6) {

                Image(
                    systemName:
                        systemImage
                )
                .foregroundColor(
                    color
                )

                Text(label)
                    .font(
                        .caption.weight(
                            .medium
                        )
                    )
                    .foregroundColor(
                        .secondary
                    )
            }


            Text(value)
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundColor(
                    .primary
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.55
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            color.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .stroke(
                color.opacity(0.18),
                lineWidth: 1
            )
        )
    }
}


// MARK: - Session Stat

private struct SessionStat: View {

    let label: String
    let value: String
    let color: Color

    var body: some View {

        VStack(spacing: 3) {

            Text(label)
                .font(.caption2)
                .foregroundColor(
                    .secondary
                )

            Text(value)
                .font(
                    .system(
                        size: 13,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .foregroundColor(
                    color
                )
        }
        .frame(
            maxWidth: .infinity
        )
    }
}


// MARK: - Result Metric

private struct ResultMetric: View {

    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {

        VStack(spacing: 7) {

            Image(
                systemName: icon
            )
            .font(.title3)
            .foregroundColor(
                iconColor
            )

            Text(value)
                .font(
                    .system(
                        size: 17,
                        weight: .bold,
                        design: .monospaced
                    )
                )

            Text(label)
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity
        )
    }
}


// MARK: - Section Title

private struct SectionTitle: View {

    let title: String
    let icon: String

    var body: some View {

        Label(
            title,
            systemImage: icon
        )
        .font(
            .caption.weight(
                .semibold
            )
        )
        .foregroundColor(
            .secondary
        )
    }
}


// MARK: - Tab Button

private struct TabButton: View {

    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: 5) {

                Image(
                    systemName: icon
                )

                Text(title)
            }
            .font(
                .caption.weight(
                    isSelected
                    ? .semibold
                    : .regular
                )
            )
            .foregroundColor(
                isSelected
                ? .primary
                : .secondary
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(.vertical, 6)
            .background(
                isSelected
                ? Color.primary.opacity(0.10)
                : Color.clear
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 6,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Live Badge

private struct LiveBadge: View {

    let isOn: Bool

    var body: some View {

        HStack(spacing: 5) {

            Circle()
                .fill(
                    isOn
                    ? Color.green
                    : Color.gray
                )
                .frame(
                    width: 7,
                    height: 7
                )

            Text(
                isOn
                ? "Live"
                : "Paused"
            )
            .font(
                .caption.weight(
                    .medium
                )
            )
            .foregroundColor(
                isOn
                ? .green
                : .secondary
            )
        }
        .padding(
            .horizontal,
            9
        )
        .padding(
            .vertical,
            4
        )
        .background(
            (
                isOn
                ? Color.green
                : Color.gray
            )
            .opacity(0.10)
        )
        .clipShape(
            Capsule()
        )
    }
}
