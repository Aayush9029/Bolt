//
//  SMCError.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-30.
//

import Foundation

enum SMCError: Error {
    case driverNotFound
    case failedToOpen
    case keyNotFound(code: String)
    case notPrivileged
    case unknown(kIOReturn: kern_return_t, SMCResult: UInt8)
}
