//
//  Logger+Extension.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation
import os

extension Logger {
    init(category: String) {
        self.init(
            subsystem: Bundle.main.bundleIdentifier ?? "com.aayush.opensource.Bolt.Helper",
            category: category
        )
    }
}
