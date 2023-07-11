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
import XPC

@Observable class BoltViewModel {
    var batteryInfo: BatteryInfo? = .init(info: [:])
    var xpcSessionConnected: Bool = false

    var bclmValue: Int = 50

    private var logger = Logger(category: "🔄")
    private var batteryStatusTimer: Timer? = .none
    private var refreshInterval: TimeInterval = 10.0

    private var xpcConnectTimer: Timer? = .none
    private var xpcConnectInterval: TimeInterval = 30.0
    private var session: XPCSession? = .none

    init() {
        refreshBatteryStatus()
        xpcConnectTimer = Timer.scheduledTimer(withTimeInterval: xpcConnectInterval, repeats: true) { _ in
            self.connectXPC()
        }
        batteryStatusTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            self.refreshBatteryStatus()
        }
    }

    deinit {
        batteryStatusTimer?.invalidate()
        xpcConnectTimer?.invalidate()
    }

    func updateBCLM(newValue: Int) {
        logger.log("Updating BCLM Value : \(newValue)")
        bclmValue = newValue
    }

    func connectXPC() {
        logger.error("Connecting to XPC")

        if xpcSessionConnected {
            logger.log("Session is already active")
            xpcConnectTimer?.invalidate()
        }

        do {
            session = try .init(xpcService: "xpc.aayush.opensource.bolt")
            xpcConnectTimer?.invalidate()
            try session?.activate()
            xpcSessionConnected = true
            logger.debug("XPC Service Activated")
        } catch {
            logger.error("Couldn't initialize XPC Service \(error.localizedDescription)")
        }
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
