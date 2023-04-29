//
//  Bundle+Extension.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-29.
//

import Foundation

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}
