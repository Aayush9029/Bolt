//
//  CheckForUpdates.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-29.
//

import MacControlCenterUI
import Sparkle
import SwiftUI

struct CheckForUpdates: View {
    @ObservedObject private var appUpdateVM: AppUpdaterViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater

        // Create our view model for our CheckForUpdatesView
        self.appUpdateVM = AppUpdaterViewModel(updater: updater)
    }

    var body: some View {
        MenuCommand("Check for Updates...") {
            updater.checkForUpdates()
        }.disabled(!appUpdateVM.canCheckForUpdates)
            .opacity(appUpdateVM.canCheckForUpdates ? 1 : 0.5)
            .padding(.horizontal, -16)
    }
}
