//
//  BoltViewModel.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import Foundation
import IOKit.ps
import IOKit.pwr_mgt
import SwiftUI

final class BoltViewModel: ObservableObject {
    @AppStorage("boltActive") var active: Bool = false
    @Published var limitCharge: CGFloat = 0.75
    let boltHelper = BoltHelper.shared

    var bclmValue: Int {
        return Int(limitCharge * 100)
    }

    init() {
//        fetchBCLMValue()
        getCurrentBattery()
    }

    func fetchBCLMValue() {
        boltHelper.readBCLM { value in
            DispatchQueue.main.async {
                self.limitCharge = CGFloat(value / 100)
            }
        }
    }

    func updateBCLMValue(newValue: Int) {
        boltHelper.writeBCLM(value: newValue)
    }

    func getCurrentBattery() -> Int? {
        // Take a snapshot of all the power source info
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()

        // Pull out a list of power sources
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        // For each power source...
        for ps in sources {
            // Fetch the information for a given power source out of our snapshot
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: AnyObject]

            // Pull out the name and capacity
            if let name = info[kIOPSNameKey] as? String,
               let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let max = info[kIOPSMaxCapacityKey] as? Int
            {
                if max > 50 {
                    return capacity
                }
                print("\(name): \(capacity) of \(max)")
            }
        }
        return nil
    }
}

final class BoltHelper: NSObject {
    static let shared = BoltHelper()

    private var modifiedKeys: [String: UInt8] = [:]

    override private init() {}

    func readBCLM(completion: @escaping (UInt8) -> Void) {
        readSMCByte(key: "BCLM", completion: completion)
    }

    func writeBCLM(value: Int) {
        writeSMCByte(key: "BCLM", value: UInt8(value))
        writeSMCByte(key: "BFCL", value: UInt8(value - 5))
    }

    private func readSMCByte(key: String, completion: @escaping (UInt8) -> Void) {
        do {
            try SMCKit.open()
            let smcKey = SMCKit.getKey(key, type: DataTypes.UInt8)
            let status = try SMCKit.readData(smcKey).0
            completion(status)
        } catch {
            print(error)
            completion(0)
        }
    }

    private func writeSMCByte(key: String, value: UInt8) {
        do {
            try SMCKit.open()
            let smcKey = SMCKit.getKey(key, type: DataTypes.UInt8)
            let bytes: SMCBytes = (value, UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0))

            if modifiedKeys[key] == nil {
                try? SMCKit.writeData(smcKey, data: bytes)
            } else {
                readSMCByte(key: key) { originalValue in
                    self.modifiedKeys[key] = originalValue
                    try? SMCKit.writeData(smcKey, data: bytes)
                }
            }
        } catch {
            print(error)
        }
    }
}
