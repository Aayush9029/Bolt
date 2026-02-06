//
//  main.swift
//  Helper
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation
import os

let logger = Logger(
    subsystem: "com.aayush.opensource.Bolt.Helper",
    category: "main"
)

// MARK: - Open SMC connection with retry

func openSMCWithRetry(attempts: Int = 3) {
    var currentAttempt = 0
    while currentAttempt < attempts {
        do {
            try SMCKit.open()
            logger.info("SMC connection opened successfully")
            return
        } catch {
            currentAttempt += 1
            logger.error("SMC open attempt \(currentAttempt)/\(attempts) failed: \(error.localizedDescription)")
            if currentAttempt < attempts {
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }
    logger.critical("Failed to open SMC after \(attempts) attempts")
}

// MARK: - XPC Listener Delegate

class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        logger.info("Accepting new XPC connection")

        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        newConnection.exportedObject = HelperXPCHandler()

        newConnection.invalidationHandler = {
            logger.info("XPC connection invalidated")
        }
        newConnection.interruptionHandler = {
            logger.warning("XPC connection interrupted")
        }

        newConnection.resume()
        return true
    }
}

// MARK: - Start

logger.info("BoltHelper starting (version \(helperVersion))")

openSMCWithRetry()

let delegate = HelperListenerDelegate()
let listener = NSXPCListener(machServiceName: "com.aayush.opensource.Bolt.Helper.mach")
listener.delegate = delegate
listener.resume()

logger.info("XPC listener active on com.aayush.opensource.Bolt.Helper.mach")

RunLoop.main.run()
