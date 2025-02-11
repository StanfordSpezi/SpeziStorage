//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security


/// Specifies how a keychain item should be stored.
/// - Important: Not all storage options are supported for all item kinds; for example, password items cannot be stored into the secure enclave.
public enum KeychainItemStorageOption: Hashable, Sendable {
    /// Store a cryptographic key in the secure enclave.
    /// - Important: This option is only compatible with cryptographic keys. Attempting to store e.g. credentials into the secure enclave will fail.
    case secureEnclave(requireUserPresence: Bool)
    
    /// Store an item in the keychain.
    /// - parameter requireUserPresence: Whether the keychain item should be configured in a way that it is only accessible if the user was present at the very last minute before the item is retrieved from the keychain
    /// - parameter accessGroup: The optional access group used to store the item
    ///
    /// ## See also
    /// - https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility
    /// - https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    case keychain(requireUserPresence: Bool = false, accessGroup: String? = nil)
    
    /// Store the element in the Keychain, and optionally allow it be synchronized across the user's devices.
    /// - parameter accessGroup: The optional access group used to store the item
    case keychainSynchronizable(accessGroup: String?)
}


extension KeychainItemStorageOption {
    /// Stores a keychain item in the secure enclave, without requiring user presence to access the item.
    public static let secureEnclave = Self.secureEnclave(requireUserPresence: false)
    /// Stores a keychain item in the keychain, without requiring user presence to access the item and without associating it with any particular access group.
    public static let keychain = Self.keychain(requireUserPresence: false, accessGroup: nil)
    /// Store an item in the keychain and enable synchronization across multiple devices belonging to the user.
    public static let keychainSynchronizable = Self.keychainSynchronizable(accessGroup: nil)
}


extension KeychainItemStorageOption {
    public var id: String {
        switch self {
        case .secureEnclave(let requireUserPresence):
            return "secureEnclave(\(requireUserPresence))"
        case .keychain(let requireUserPresence, .none):
            return "keychain(\(requireUserPresence))"
        case .keychain(let requireUserPresence, .some(let accessGroup)):
            return "keychain(\(requireUserPresence);\(accessGroup))"
        case .keychainSynchronizable(accessGroup: .none):
            return "keychainSynchronizable"
        case .keychainSynchronizable(accessGroup: .some(let accessGroup)):
            return "keychainSynchronizable(\(accessGroup))"
        }
    }
    
    var requireUserPresence: Bool {
        switch self {
        case let .secureEnclave(requireUserPresence), let .keychain(requireUserPresence, _):
            requireUserPresence
        case .keychainSynchronizable:
            false
        }
    }
    
    var accessGroup: String? {
        switch self {
        case .secureEnclave:
            nil
        case .keychain(_, let accessGroup), .keychainSynchronizable(let accessGroup):
            accessGroup
        }
    }
    
    var isSynchronizable: Bool {
        switch self {
        case .secureEnclave, .keychain:
            false
        case .keychainSynchronizable:
            true
        }
    }
    
    var isSecureEnclave: Bool {
        switch self {
        case .secureEnclave:
            true
        case .keychain, .keychainSynchronizable:
            false
        }
    }
}
