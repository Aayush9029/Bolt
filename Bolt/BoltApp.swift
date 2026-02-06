//
//  BoltApp.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import MacControlCenterUI
import SwiftUI

@main
struct BoltApp: App {
    var boltVM: BoltViewModel = .init()

    init() {
        // Register the helper daemon on launch
        ServiceManager.instance.registerDaemons()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(boltVM)
        } label: {
            Label("Bolt", systemImage: boltVM.bclmValue >= 100 ? "bolt" : "bolt.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
