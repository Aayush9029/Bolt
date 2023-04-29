//
//  BoltApp.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import MacControlCenterUI
import Sparkle
import SwiftUI

@main
struct BoltApp: App {
    @StateObject var boltVM: BoltViewModel = .init()
    @State var isPresented: Bool = true

    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView(isPresented: $isPresented, updater: updaterController.updater)
                .environmentObject(boltVM)
        } label: {
            Label("Bolt", systemImage: boltVM.limitCharge > 0.95 ? "bolt" : "bolt.fill")
        }

        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdates(updater: updaterController.updater)
            }
        }
    }
}
