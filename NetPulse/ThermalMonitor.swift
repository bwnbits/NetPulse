//
//  ThermalMonitor.swift
//  NetPulse
//
//  Created by A.R. on 18/08/26.
//

import Foundation
import Combine
import SwiftUI

final class ThermalMonitor: ObservableObject {

    @Published private(set) var thermalState:
        ProcessInfo.ThermalState = .nominal

    private var timer: Timer?

    init() {

        updateThermalState()

        timer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateThermalState()
        }
    }

    private func updateThermalState() {

        DispatchQueue.main.async { [weak self] in

            guard let self else {
                return
            }

            self.thermalState =
                ProcessInfo.processInfo.thermalState
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Status Text

    var statusText: String {

        switch thermalState {

        case .nominal:
            return "Normal"

        case .fair:
            return "Warm"

        case .serious:
            return "Hot"

        case .critical:
            return "Critical"

        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Icon

    var icon: String {

        switch thermalState {

        case .nominal:
            return "thermometer.medium"

        case .fair:
            return "thermometer.sun"

        case .serious:
            return "thermometer.high"

        case .critical:
            return "thermometer.sun.fill"

        @unknown default:
            return "thermometer.medium"
        }
    }

    // MARK: - Color

    var color: Color {

        switch thermalState {

        case .nominal:
            return .green

        case .fair:
            return .yellow

        case .serious:
            return .orange

        case .critical:
            return .red

        @unknown default:
            return .secondary
        }
    }
}
