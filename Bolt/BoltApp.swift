//
//  BoltApp.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import SwiftUI

@main
struct BoltApp: App {
    var body: some Scene {
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
