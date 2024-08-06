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
    /// Keys as created with (``SecureStorage/createKey(_:size:storageScope:)``).
    public static let keys = SecureStorageItemTypes(rawValue: 1 << 0)
    /// Credentials as created with (``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``) by passing in a server name.
    public static let serverCredentials = SecureStorageItemTypes(rawValue: 1 << 1)
    /// Credentials as created with (``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``) by omitting a server name.
    public static let nonServerCredentials = SecureStorageItemTypes(rawValue: 1 << 2)
    
    /// Credentials as created with (``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``).
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
