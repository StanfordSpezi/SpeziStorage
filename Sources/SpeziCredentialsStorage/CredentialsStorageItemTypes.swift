//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security


/// Types of items that can be stored in the ``CredentialsStorage``.
public struct CredentialsStorageItemTypes: OptionSet {
    /// Any keys created with the `CredentialsStorage` module.
    ///
    /// Refers to any keys created using ``CredentialsStorage/createKey(for:size:storageScope:)``.
    public static let keys = CredentialsStorageItemTypes(rawValue: 1 << 0)
    
    /// Credentials that are created using a server name.
    ///
    /// Refers to any credentials that are stored using a server name using ``CredentialsStorage/store(_:for:removeDuplicate:)``.
    public static let serverCredentials = CredentialsStorageItemTypes(rawValue: 1 << 1)
    
    /// Credentials that are created without supplying a server name.
    ///
    /// Refers to any credentials that are stored without using a server name using ``CredentialsStorage/store(_:for:removeDuplicate:)``.
    public static let nonServerCredentials = CredentialsStorageItemTypes(rawValue: 1 << 2)

    /// Any credentials created with the `CredentialsStorage` module.
    ///
    /// Refers to any credentials that are created using  ``CredentialsStorage/store(_:for:removeDuplicate:)``.
    public static let credentials: CredentialsStorageItemTypes = [.serverCredentials, .nonServerCredentials]
    
    /// All types of items that can be handled by the credentials storage component.
    public static let all: CredentialsStorageItemTypes = [.keys, .serverCredentials, .nonServerCredentials]
    
    
    public let rawValue: Int
    
    
    var kSecClass: [CFString] {
        var kSecClass: [CFString] = []
        if self.contains(.keys) {
            kSecClass.append(kSecClassKey)
        }
        if self.contains(.serverCredentials) {
            kSecClass.append(kSecClassGenericPassword)
        }
        if self.contains(.nonServerCredentials) {
            kSecClass.append(kSecClassInternetPassword)
        }
        return kSecClass
    }
    
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}


extension CredentialsStorageItemTypes: Sendable {}
