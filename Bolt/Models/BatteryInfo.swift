//
//  BatteryInfo.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-29.
//

import Foundation

struct BatteryInfo {
    let batteryHealth: String?
    let maxCapacity: Int?
    let optimizedBatteryChargingEngaged: Bool?
    let timeToEmpty: Int?
    let lpmActive: Bool?
    let isCharging: Bool?
    let isPresent: Bool?
    let name: String?
    let current: Int?
    let timeToFullCharge: Int?
    let currentCapacity: Int?
    let type: String?
    let powerSourceID: Int?
    let hardwareSerialNumber: String?
    let transportType: String?
    let batteryProvidesTimeRemaining: Int?
    let designCycleCount: Int?
    let powerSourceState: String?
    let batteryHealthCondition: String?

    init(info: [String: AnyObject]) {
        batteryHealth = info["BatteryHealth"] as? String
        maxCapacity = info["Max Capacity"] as? Int
        optimizedBatteryChargingEngaged = info["Optimized Battery Charging Engaged"] as? Bool
        timeToEmpty = info["Time to Empty"] as? Int
        powerSourceID = info["Power Source ID"] as? Int
        isCharging = info["Is Charging"] as? Bool
        hardwareSerialNumber = info["Hardware Serial Number"] as? String
        transportType = info["Transport Type"] as? String
        batteryProvidesTimeRemaining = info["Battery Provides Time Remaining"] as? Int
        isPresent = info["Is Present"] as? Bool
        designCycleCount = info["DesignCycleCount"] as? Int
        powerSourceState = info["Power Source State"] as? String
        name = info["Name"] as? String
        batteryHealthCondition = info["BatteryHealthCondition"] as? String
        current = info["Current"] as? Int
        timeToFullCharge = info["Time to Full Charge"] as? Int
        currentCapacity = info["Current Capacity"] as? Int
        lpmActive = info["LPM Active"] as? Bool
        type = info["Type"] as? String
    }

    func timeToEmptyFormatted() -> String? {
        guard var timeToEmpty = timeToEmpty else { return nil }
        timeToEmpty = timeToEmpty * 60
        let hours = timeToEmpty / 3600
        let minutes = (timeToEmpty % 3600) / 60
        let seconds = timeToEmpty % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var properties: [(key: String, value: String)] {
        return [
            ("Power Source", powerSourceState ?? ""),
            ("Max Capacity", (maxCapacity != nil) ? "\(maxCapacity!)%" : ""),
            ("Charging", isCharging.map(String.init) ?? ""),
            ("Low Power Mode", lpmActive.map(String.init) ?? ""),
            ("Optimized Battery Charging (system)", optimizedBatteryChargingEngaged.map(String.init) ?? ""),
            ("Transport Type", transportType ?? ""),
            ("Is Present", isPresent.map(String.init) ?? ""),
            ("Design Cycle Count", designCycleCount.map(String.init) ?? ""),
            ("Current (amperes)", current.map(String.init) ?? ""),
            ("Power Source ID", powerSourceID.map(String.init) ?? ""),
            ("Serial Number", hardwareSerialNumber ?? ""),
        ]
    }
}
