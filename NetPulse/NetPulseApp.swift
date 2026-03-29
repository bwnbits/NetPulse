//
//  NetPulseApp.swift
//  NetPulse
//
//  Created by Abhishek Ruhela on 3/29/26.
//
import SwiftUI

@main
struct NetPulseApp: App {
    
    @StateObject var monitor = NetworkSpeedMonitor()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
                .frame(width: 280, height: 240)
        } label: {
            MenuBarView(monitor: monitor)
        }
    }
}
