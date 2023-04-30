//
//  HelperProtocol.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation
import IOKit.pwr_mgt

@objc(HelperToolProtocol) protocol HelperToolProtocol {
    func getVersion(withReply reply: @escaping (String) -> Void)

    func setSMCByte(key: String, value: UInt8)
    func readSMCByte(key: String, withReply reply: @escaping (UInt8) -> Void)
    func readSMCUInt32(key: String, withReply reply: @escaping (UInt32) -> Void)

    func createAssertion(assertion: String, withReply reply: @escaping (IOPMAssertionID) -> Void)
    func releaseAssertion(assertionID: IOPMAssertionID)
    func setResetVal(key: String, value: UInt8)
}

let helperVersion: String = "1"
