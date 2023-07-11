//
//  main.swift
//  Helper
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation
import os
import XPC

let helperServer = HelperServer()

class HelperServer {
    var xpcSessionConnected: Bool = false
    private let logger = Logger(category: "🌐")

    private var xpcConnectTimer: Timer? = .none
    private var xpcConnectInterval: TimeInterval = 30.0
    private var session: XPCSession? = .none
    private var listener: XPCListener? = .none

    init() {
        xpcConnectTimer = Timer.scheduledTimer(withTimeInterval: xpcConnectInterval, repeats: true) { _ in
            self.connectXPC()
        }
    }

    func connectXPC() {
        logger.error("Connecting to XPC")

        if xpcSessionConnected {
            logger.log("Session is already active")
            xpcConnectTimer?.invalidate()
        }

        do {
            session = try .init(xpcService: "xpc.aayush.opensource.bolt")
            listener = try .init(service: "xpc.aayush.opensource.bolt", incomingSessionHandler: { _ in

            })
            xpcConnectTimer?.invalidate()
            try session?.activate()
            xpcSessionConnected = true
            logger.debug("XPC Service Activated")
        } catch {
            logger.error("Couldn't initialize XPC Service \(error.localizedDescription)")
        }
    }
}
