//
//  ServiceManager.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import IOKit.pwr_mgt
import os
import ServiceManagement
import SwiftUI

// Install + Communicate with SMC Daemon
final class ServiceManager {
    private lazy var logger = Logger(category: "🍎")
    static let instance = ServiceManager()
    
    public var delegate: HelperDelegate?
    private var smcKey: String?
    private var preventSleepID: IOPMAssertionID?
    public var chargingEnabled: Bool = true
    public var helperRunning: Bool = false
    
    // The identifier must match the CFBundleIdentifier string in Info.plist.
    // LaunchDaemon path: $APP.app/Contents/Library/LaunchDaemons/
    let loginPrivilegedDaemon = SMAppService.daemon(plistName: "com.aayush.opensource.Bolt.Helper.plist")
    
    lazy var helperToolConnection: NSXPCConnection = {
        let connection = NSXPCConnection(machServiceName: "com.aayush.opensource.Bolt.Helper.mach", options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
        connection.resume()
        return connection
    }()
    
    // MARK: - Service Management Functions
    
    func servicesEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    func disableAppService() {
        try? SMAppService.mainApp.unregister()
    }
    
    func enableAppService() {
        try? SMAppService.mainApp.register()
    }
    
    func registerDaemons() {
        logger.debug("registering Services")
        register(loginPrivilegedDaemon)
    }
    
    func removeDaemons() {
        logger.debug("Un-registering Services")
        unregister(loginPrivilegedDaemon)
    }
    
    func getStatus() {
        logger.info("Getting Services status")
        status(loginPrivilegedDaemon)
    }
    
    // MARK: - Charging Functions
    
    func toggleCharging() {
        SMCWriteByte(key: "CH0B", value: chargingEnabled ? 02 : 00)
        chargingEnabled.toggle()
    }
    
    func checkCharging() {
        ServiceManager.instance.SMCReadUInt32(key: "CH0B") { value in
            self.chargingEnabled = (value == 00)
            self.logger.info("\(self.chargingEnabled ? "CHARGING" : "NOT CHARGING")")
        }
    }
    
    // MARK: - Sleep Functions
    
    func enableSleep() {
        if preventSleepID != nil {
            logger.info("Allowing system sleep")
            releaseAssertion(assertionID: preventSleepID!)
            preventSleepID = nil
        }
    }
    
    func disableSleep() {
        createAssertion(assertion: kIOPMAssertionTypePreventSystemSleep) { id in
            if self.preventSleepID == nil {
                self.logger.info("Preventing system sleep")
                self.preventSleepID = id
            }
        }
    }
    
    // MARK: - SMC Functions

    @objc func setResetValues() {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            
        } as? HelperToolProtocol
        
        helper?.setResetVal(key: "CH0B", value: 00)
    }
    
    @objc func writeMaxBatteryCharge(setVal: UInt8) {
        SMCWriteByte(key: "BCLM", value: setVal)
    }
    
    @objc func readMaxBatteryCharge() {
        SMCReadByte(key: "BCLM") { value in
            print("OLD KEY MAX CHARGE: " + String(value))
            self.delegate?.OnMaxBatRead(value: value)
        }
    }
    
    @objc func enableCharging(enabled: Bool) {
        SMCWriteByte(key: "CH0B", value: enabled ? 00 : 02)
    }
    
    @objc func SMCReadByte(key: String, withReply reply: @escaping (UInt8) -> Void) {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            
        } as? HelperToolProtocol
        
        helper?.readSMCByte(key: key) {
            reply($0)
        }
    }
    
    @objc func SMCReadUInt32(key: String, withReply reply: @escaping (UInt32) -> Void) {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            
        } as? HelperToolProtocol
        
        helper?.readSMCUInt32(key: key) {
            reply($0)
        }
    }
    
    @objc func SMCWriteByte(key: String, value: UInt8) {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            
        } as? HelperToolProtocol
        
        helper?.setSMCByte(key: key, value: value)
    }
    
    func getChargingInfo(withReply reply: (String, Int, Bool, Int) -> Void) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        let info = IOPSGetPowerSourceDescription(snapshot, sources[0]).takeUnretainedValue() as! [String: AnyObject]
        
        if let name = info[kIOPSNameKey] as? String,
           let capacity = info[kIOPSCurrentCapacityKey] as? Int,
           let isCharging = info[kIOPSIsChargingKey] as? Bool,
           let max = info[kIOPSMaxCapacityKey] as? Int
        {
            reply(name, capacity, isCharging, max)
        }
    }
    
    func getSMCCharge(withReply reply: @escaping (Float) -> Void) {
        ServiceManager.instance.SMCReadUInt32(key: "BRSC") { value in
            let smcval = Float(value >> 16)
            reply(smcval)
        }
    }
    
    //    MARK: - Helper Functions

    @objc func checkHelperVersion(withReply reply: @escaping (Bool) -> Void) {
        print("checking helper version")
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            reply(false)
            return ()
            
        } as? HelperToolProtocol
        
        helper?.getVersion { version in
            print("helperVersion:", helperVersion, " version from helper:", version)
            if !helperVersion.elementsEqual(version) {
                reply(false)
                return ()
            } else {
                self.helperRunning = true
                reply(true)
                return ()
            }
        }
    }
    
    @objc func createAssertion(assertion: String, withReply reply: @escaping (IOPMAssertionID) -> Void) {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
        } as? HelperToolProtocol
        
        helper?.createAssertion(assertion: assertion, withReply: { id in
            reply(id)
        })
    }
    
    @objc func releaseAssertion(assertionID: IOPMAssertionID) {
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
        } as? HelperToolProtocol
        
        helper?.releaseAssertion(assertionID: assertionID)
    }
    
    func isRoot() -> Bool {
        return NSUserName() == "root"
    }
    
    // MARK: - Private Functions
    
    private func register(_ service: SMAppService) {
        if service.status == .enabled {
            logger.info("\(service.description) status: \(service)")
        } else {
            do {
                try service.register()
            } catch {
                if error.localizedDescription.contains("Operation not permitted") {
                    logger.error("\(service.description): \(error.localizedDescription). Login item requires approval")
                } else if !error.localizedDescription.contains("Service cannot load in requested session") {
                    logger.error("\(service.description): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func unregister(_ service: SMAppService) {
        if !isRoot() {
            logger.error("Must be root to unregister \(service.description)")
            return
        }
        logger.error("MIGHT BE ABLE TO REMOVE isROOT()  SINCE BAT-FI DOESN'T USE IT")
        if service.status == .enabled {
            do {
                try service.unregister()
            } catch {
                logger.error("\(service.description): \(error.localizedDescription)")
            }
        } else {
            logger.info("\(service.description) status: \(service)")
        }
    }
    
    private func status(_ service: SMAppService) {
        logger.info("\(service.description) status: \(service)")
    }
}

protocol HelperDelegate {
    func OnMaxBatRead(value: UInt8)
    func updateStatus(status: String)
}
