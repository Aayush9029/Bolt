//
//  BoltViewModel.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import Foundation
import IOKit.pwr_mgt
import SwiftUI

final class BoltViewModel: ObservableObject {
    @Published var bclmValue: Int = 0

    private let boltHelper = BoltHelper.shared

    init() {
        fetchBCLMValue()
    }

    func fetchBCLMValue() {
        boltHelper.readBCLM { value in
            DispatchQueue.main.async {
                self.bclmValue = Int(value)
                print("BCLM VALUE: \(value)")
            }
        }
    }

    func updateBCLMValue(newValue: Int) {
        bclmValue = newValue
        boltHelper.writeBCLM(value: newValue)
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
