//
//  NetPulseApp.swift
//  NetPulse
//
//  Single source of truth: monitor created once here
//  and injected everywhere.
//

import SwiftUI

@main
struct NetPulseApp: App {

    @StateObject private var monitor = NetworkSpeedMonitor()

    var body: some Scene {

        // ── Main Window ───────────────────────────────────────────
        // Optional — can be hidden if NetPulse is used purely
        // as a menu-bar application.
        WindowGroup {
            MainWindowView()
                .environmentObject(monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // ── Menu Bar ──────────────────────────────────────────────
        MenuBarExtra {
            ContentView()
                .environmentObject(monitor)
                .frame(width: 300)
        } label: {
            MenuBarView()
                .environmentObject(monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
