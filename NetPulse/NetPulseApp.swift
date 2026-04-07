// NetPulseApp.swift
// NetPulse
//
// Single source of truth: monitor created once here and injected everywhere.

import SwiftUI

@main
struct NetPulseApp: App {

    @StateObject private var monitor = NetworkSpeedMonitor()

    var body: some Scene {

        // Main window (optional — can be hidden if pure menu-bar app)
        WindowGroup {
            MainWindowView()
                .environmentObject(monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Menu bar
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
