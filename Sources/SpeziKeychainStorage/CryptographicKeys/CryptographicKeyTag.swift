//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import CoreFoundation
import Security


/// Identifies cryptographic keys stored in the system keychain.
///
/// - Important: Don't define and use multiple `KeyTag`s with the same underlying `tagValue`, unless you really know what you're doing. Such duplicate `KeyTag`s will likely end up referring to the same keychain item, which can cause keychain API interactions to operate on the wrong item.
public struct CryptographicKeyTag: Hashable, Sendable {
    /// The underlying raw tag value
    public let tagValue: String
    
    /// The key's label.
    ///
    /// When using ``Keychain/createKey(for:size:)`` to create a cryptographic key, this value is used to define the key's `kSecAttrLabel`.
    public let label: String?
    
    /// How the key should be stored.
    public let storage: KeychainItemStorageOption
    
    /// The key size
    public let size: Int
    
    /// The key's type
    public var keyType: CFString { kSecAttrKeyTypeECSECPrimeRandom }
    
    /// Creates a new Key Tag
    public init(_ tagValue: String, size: Int = 256, storage: KeychainItemStorageOption, label: String? = nil) {
        self.tagValue = tagValue
        self.size = size
        self.storage = storage
        self.label = label
    }
}
