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
    @State private var isPresented: Bool = true

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(boltVM)
        } label: {
            Label("Bolt", systemImage: boltVM.bclmValue > 95 ? "bolt" : "bolt.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
