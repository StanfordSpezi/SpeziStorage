//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security


/// Types of items that can be stored in the secure storage.
public struct SecureStorageItemTypes: OptionSet {
    /// Any keys created with the `SecureStorage` module.
    ///
    /// Refers to any keys created using ``SecureStorage/createKey(_:size:storageScope:)``.
    public static let keys = SecureStorageItemTypes(rawValue: 1 << 0)
    /// Credentials that are created using a server name.
    ///
    /// Refers to any credentials that are stored using a server name using ``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``.
    public static let serverCredentials = SecureStorageItemTypes(rawValue: 1 << 1)
    /// Credentials that are created without supplying a server name.
    ///
    /// Refers to any credentials that are stored without using a server name using ``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``.
    public static let nonServerCredentials = SecureStorageItemTypes(rawValue: 1 << 2)

    /// Any credentials created with the `SecureStorage` module.
    ///
    /// Refers to any credentials that are created using  ``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``.
    public static let credentials: SecureStorageItemTypes = [.serverCredentials, .nonServerCredentials]
    /// All types of items that can be handled by the secure storage component.
    public static let all: SecureStorageItemTypes = [.keys, .serverCredentials, .nonServerCredentials]
    
    
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


extension SecureStorageItemTypes: Sendable {}
