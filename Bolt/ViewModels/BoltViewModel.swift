//
//  BoltViewModel.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import Combine
import IOKit.ps
import IOKit.pwr_mgt
import os
import SwiftUI

final class BoltViewModel: ObservableObject {
    private lazy var logger = Logger(category: "🔄")

    @Published var batteryInfo: BatteryInfo?
    @Published var limitCharge: CGFloat = 0.0 {
        didSet {
            valueChangedSubject.send(limitCharge)
        }
    }

    var bclmValue: Int { return Int(limitCharge * 100) }

    private var cancellable: AnyCancellable?
    private let valueChangedSubject = PassthroughSubject<CGFloat, Never>()
    private var batteryStatusTimer: Timer?
    private var refreshInterval: TimeInterval = 10.0

    init() {
        cancellable = valueChangedSubject
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { _ in
                self.updateBCLMValue(newValue: self.bclmValue)
            }
        refreshBatteryStatus()

        batteryStatusTimer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { _ in
            self.refreshBatteryStatus()
        }
    }

    deinit {
        batteryStatusTimer?.invalidate()
    }

    private func updateBCLMValue(newValue: Int) {
        logger.log("Updating BCLM Value : \(newValue)")
    }

    func refreshBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for ps in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: AnyObject] else { return }

            if (info[kIOPSMaxCapacityKey] as? Int ?? 0) > 50 {
                DispatchQueue.main.async {
                    self.batteryInfo = BatteryInfo(info: info)
                    self.logger.debug("""
                    State updated:
                        Charging : \(self.batteryInfo?.isCharging ?? false)
                        Battery  : \(self.batteryInfo?.currentCapacity ?? -1)
                        Source   : \(self.batteryInfo?.powerSourceState ?? "Unknown")
                    """)
                }
            }
        }
    }
}
