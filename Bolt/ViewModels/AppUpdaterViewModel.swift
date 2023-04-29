//
//  AppUpdaterViewModel.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-29.
//

import Sparkle
import SwiftUI

final class AppUpdaterViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
