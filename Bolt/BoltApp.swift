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
            Label("Bolt", systemImage: boltVM.limitCharge > 0.95 ? "bolt" : "bolt.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
