//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation

public struct CredentialTypes: OptionSet {
    /// Credentials that are created using a server name.
    ///
    /// Refers to any credentials that are stored with a server name using ``CredentialStorage``.
    public static let server = CredentialTypes(rawValue: 1 << 1)
    /// Credentials that are created without supplying a server name.
    ///
    /// Refers to any credentials that are stored without a server name using ``CredentialStorage``.
    public static let nonServer = CredentialTypes(rawValue: 1 << 2)

    /// Any credentials created with the `CredentialStorage` module.
    ///
    /// Refers to any credentials that are created using  ``CredentialStorage``.
    public static let all: CredentialTypes = [.server, .nonServer]
    
    var kSecClasses: [CFString] {
        var kSecClasses: [CFString] = []
        if self.contains(.server) {
            kSecClasses.append(kSecClassGenericPassword)
        }
        if self.contains(.nonServer) {
            kSecClasses.append(kSecClassInternetPassword)
        }
        return kSecClasses
    }
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension CredentialTypes: Sendable {}
