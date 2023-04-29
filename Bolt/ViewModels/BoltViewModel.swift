//
//  BoltViewModel.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import Combine
import Foundation
import IOKit.ps
import IOKit.pwr_mgt
import SwiftUI

final class BoltViewModel: ObservableObject {
    let boltHelper = BoltHelper.shared

    @Published var batteryInfo: BatteryInfo?
    @Published var limitCharge: CGFloat = 0.0 {
        didSet {
            valueChangedSubject.send(limitCharge)
        }
    }

    var bclmValue: Int { return Int(limitCharge * 100) }

    private var cancellable: AnyCancellable?
    private let valueChangedSubject = PassthroughSubject<CGFloat, Never>()

    init() {
        cancellable = valueChangedSubject
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { _ in
                self.updateBCLMValue(newValue: self.bclmValue)
            }
        refreshBCLMValue()
        refreshBatteryStatus()
    }

    func refreshBCLMValue() {
        boltHelper.readBCLM { value in
            DispatchQueue.main.async {
                self.limitCharge = CGFloat(value / 100)
            }
        }
    }

    private func updateBCLMValue(newValue: Int) {
        print("Writing to smc: \(newValue)")
        boltHelper.writeBCLM(value: newValue)
    }

    func refreshBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        // For each power source...
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: AnyObject]
            // Pull out the name and capacity
            if (info[kIOPSMaxCapacityKey] as? Int ?? 0) > 50 {
                DispatchQueue.main.async {
                    self.batteryInfo = BatteryInfo(info: info)
                }
            }
        }
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
        if value < 20 { return }
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
                print("SMC: Wrote data, \(value)")
            } else {
                print("SMC: Error Writing data, \(value)")
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
