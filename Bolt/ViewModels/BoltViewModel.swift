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
import ServiceManagement
import SwiftUI

@Observable class BoltViewModel {
    var batteryInfo: BatteryInfo? = .init(info: [:])
    var bclmValue: Int {
        didSet {
            UserDefaults.standard.set(bclmValue, forKey: "bclmValue")
            applyChargeLimit()
        }
    }

    var helperStatus: SMAppService.Status = .notFound
    var chargingInhibited: Bool = false

    private var logger = Logger(category: "ViewModel")
    private var batteryStatusTimer: Timer?
    private var helperCheckTimer: Timer?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "bclmValue")
        bclmValue = saved > 0 ? saved : 80

        refreshBatteryStatus()
        refreshHelperStatus()

        batteryStatusTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.refreshBatteryStatus()
            self?.evaluateCharging()
        }

        helperCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.refreshHelperStatus()
        }

        checkHelperAndReadBCLM()
    }

    deinit {
        batteryStatusTimer?.invalidate()
        helperCheckTimer?.invalidate()
    }

    // MARK: - Helper Management

    func refreshHelperStatus() {
        helperStatus = ServiceManager.instance.loginPrivilegedDaemon.status
        logger.debug("Helper status: \(String(describing: self.helperStatus))")
    }

    var isHelperRunning: Bool {
        helperStatus == .enabled
    }

    func installHelper() {
        ServiceManager.instance.registerDaemons()
        refreshHelperStatus()
    }

    func removeHelper() {
        ServiceManager.instance.removeDaemons()
        refreshHelperStatus()
    }

    // MARK: - BCLM / Charging Control

    func applyChargeLimit() {
        guard isHelperRunning else {
            logger.warning("Helper not running, cannot apply charge limit")
            return
        }

        logger.info("Setting BCLM to \(self.bclmValue)")
        ServiceManager.instance.writeMaxBatteryCharge(setVal: UInt8(min(bclmValue, 100)))
        evaluateCharging()
    }

    func evaluateCharging() {
        guard isHelperRunning else { return }
        guard let info = batteryInfo, let capacity = info.currentCapacity else { return }

        if bclmValue >= 100 {
            // No limit — ensure charging is enabled, reset keys
            if chargingInhibited {
                ServiceManager.instance.setResetValues()
                chargingInhibited = false
                logger.info("Charge limit disabled, charging enabled")
            }
            return
        }

        if capacity >= bclmValue {
            // At or above limit — inhibit charging
            if !chargingInhibited {
                ServiceManager.instance.enableCharging(enabled: false)
                chargingInhibited = true
                logger.info("Battery at \(capacity)% >= limit \(self.bclmValue)%, inhibiting charging")
            }
        } else {
            // Below limit — allow charging
            if chargingInhibited {
                ServiceManager.instance.enableCharging(enabled: true)
                chargingInhibited = false
                logger.info("Battery at \(capacity)% < limit \(self.bclmValue)%, allowing charging")
            }
        }
    }

    private func checkHelperAndReadBCLM() {
        ServiceManager.instance.checkHelperVersion { [weak self] running in
            guard let self, running else { return }
            ServiceManager.instance.SMCReadByte(key: "BCLM") { value in
                DispatchQueue.main.async {
                    if value > 0 && value <= 100 {
                        self.logger.info("Read BCLM from SMC: \(value)")
                        // Only use SMC value if user hasn't set one yet
                        let saved = UserDefaults.standard.integer(forKey: "bclmValue")
                        if saved == 0 {
                            self.bclmValue = Int(value)
                        }
                    }
                    self.evaluateCharging()
                }
            }
        }
    }

    // MARK: - Battery Status

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
