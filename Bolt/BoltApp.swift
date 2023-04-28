//
//  BoltApp.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import SwiftUI

@main
struct BoltApp: App {
    @StateObject var boltVM: BoltViewModel = .init()
    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(boltVM)
        } label: {
            Label("Bolt", systemImage: boltVM.active ? "bolt.fill" : "bolt")
        }
        .menuBarExtraStyle(.window)

        WindowGroup {
            BoltIntroView()
                .frame(width: 520, height: 640)
                .background(
                    VisualEffectBlur(
                        material: .fullScreenUI,
                        blendingMode: .behindWindow
                    )
                    .ignoresSafeArea()
                )
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
