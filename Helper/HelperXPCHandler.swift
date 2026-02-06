//
//  HelperXPCHandler.swift
//  Helper
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation
import IOKit.pwr_mgt
import os

class HelperXPCHandler: NSObject, HelperToolProtocol {
    private let logger = Logger(
        subsystem: "com.aayush.opensource.Bolt.Helper",
        category: "XPCHandler"
    )

    // MARK: - Version

    func getVersion(withReply reply: @escaping (String) -> Void) {
        logger.debug("getVersion called")
        reply(helperVersion)
    }

    // MARK: - SMC Read/Write

    func setSMCByte(key: String, value: UInt8) {
        logger.debug("setSMCByte: \(key) = \(value)")
        do {
            let smcKey = SMCKey(
                code: FourCharCode(fromString: key),
                info: DataTypes.UInt8
            )
            try SMCKit.writeData(smcKey, uint8: value)
            logger.info("Successfully wrote \(value) to \(key)")
        } catch {
            logger.error("Failed to write SMC key \(key): \(error.localizedDescription)")
        }
    }

    func readSMCByte(key: String, withReply reply: @escaping (UInt8) -> Void) {
        logger.debug("readSMCByte: \(key)")
        do {
            let smcKey = SMCKey(
                code: FourCharCode(fromString: key),
                info: DataTypes.UInt8
            )
            let data = try SMCKit.readData(smcKey)
            logger.info("Read \(data.0) from \(key)")
            reply(data.0)
        } catch {
            logger.error("Failed to read SMC key \(key): \(error.localizedDescription)")
            reply(0)
        }
    }

    func readSMCUInt32(key: String, withReply reply: @escaping (UInt32) -> Void) {
        logger.debug("readSMCUInt32: \(key)")
        do {
            let smcKey = SMCKey(
                code: FourCharCode(fromString: key),
                info: DataTypes.UInt32
            )
            let data = try SMCKit.readData(smcKey)
            let value = UInt32(fromBytes: (data.0, data.1, data.2, data.3))
            logger.info("Read \(value) from \(key)")
            reply(value)
        } catch {
            logger.error("Failed to read SMC key \(key): \(error.localizedDescription)")
            reply(0)
        }
    }

    // MARK: - Power Assertions

    func createAssertion(assertion: String, withReply reply: @escaping (IOPMAssertionID) -> Void) {
        logger.debug("createAssertion: \(assertion)")
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            assertion as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Bolt charge management" as CFString,
            &assertionID
        )
        if result == kIOReturnSuccess {
            logger.info("Created assertion \(assertionID)")
            reply(assertionID)
        } else {
            logger.error("Failed to create assertion: \(result)")
            reply(0)
        }
    }

    func releaseAssertion(assertionID: IOPMAssertionID) {
        logger.debug("releaseAssertion: \(assertionID)")
        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            logger.info("Released assertion \(assertionID)")
        } else {
            logger.error("Failed to release assertion: \(result)")
        }
    }

    // MARK: - Reset Charging Keys

    func setResetVal(key: String, value: UInt8) {
        logger.info("Resetting charging keys to default state")
        do {
            try SMCKit.writeData(.disableCharging, uint8: 0x00)
            try SMCKit.writeData(.inhibitChargingC, uint8: 0x00)
            try SMCKit.writeData(.inhibitChargingB, uint8: 0x00)
            logger.info("All charging keys reset to 0")
        } catch {
            logger.error("Failed to reset charging keys: \(error.localizedDescription)")
        }
    }
}
