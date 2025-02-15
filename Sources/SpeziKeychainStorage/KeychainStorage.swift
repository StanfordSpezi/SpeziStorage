//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation
import Security
import Spezi


/// Securely store small chunks of sensitive data such as credentials and cryptographic keys, using the system keychain.
///
/// The storing of credentials and keys follows the Keychain documentation provided by Apple:
/// [Using the keychain to manage user secrets](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets).
///
/// - Note: Even though the `KeychainStorage` is a Spezi module, it can also be used standalone outside of Spezi.
///
/// ## Topics
/// ### Configuration
/// - ``init()``
///
/// ### Credential Storage
/// - ``Credentials``
/// - ``CredentialsTag``
/// - ``store(_:for:replaceDuplicates:)``
/// - ``updateCredentials(withUsername:for:with:)``
/// - ``retrieveCredentials(withUsername:for:)``
/// - ``retrieveAllCredentials(withUsername:for:)``
/// - ``retrieveAllGenericCredentials(forService:)``
/// -  ``retrieveAllInternetCredentials(forServer:)``
/// - ``retrieveAllCredentials()``
/// - ``deleteCredentials(withUsername:for:)``
/// - ``deleteAllGenericCredentials(service:accessGroup:)``
/// - ``deleteAllInternetCredentials(server:accessGroup:)``
/// - ``deleteAllCredentials(accessGroup:)``
///
/// ### Cryptographic Key Storage
/// - ``CryptographicKeyTag``
/// - ``createKey(for:)``
/// - ``retrievePublicKey(for:)``
/// - ``retrievePrivateKey(for:)``
/// - ``retrieveAllKeys(_:accessGroup:)``
/// - ``deleteKey(for:)``
/// - ``deleteKey(_:)``
/// - ``deleteAllKeys(accessGroup:)``
/// - ``Security/SecKey``
///
/// ### Other
/// - ``CredentialsKind``
/// - ``KeychainItemStorageOption``
/// - ``KeychainItemAccessibility``
/// - ``KeychainItemTokenID``
public final class KeychainStorage: Sendable, Module, EnvironmentAccessible, DefaultInitializable {
    /// Creates a new `KeychainStorage`.
    /// - Note: Even though this initializer will return a new object every time it is called, all `KeychainStorage` instances can be
    public init() { }
}


extension KeychainStorage {
    /// Select which access groups a keychain operation should operate on
    public enum AccessGroupFilter {
        /// The operation not filter based on access group, i.e. will apply to all acess groups
        case any
        /// The operation will filter for items of a specific access group.
        case specific(String)
        
        /// A string representation suitable for `kSecAttrAccessGroup`.
        var stringValue: String? {
            switch self {
            case .any:
                nil
            case .specific(let accessGroup):
                accessGroup
            }
        }
    }
}


extension KeychainStorage {
    enum KeychainAPIError: Error, Sendable {
        case itemNotFound
        case duplicateItem
        case missingEntitlement
        case invalidParams
        case other(OSStatus)
        
        init?(status: OSStatus) {
            switch status {
            case errSecSuccess:
                // no error
                return nil
            case errSecItemNotFound:
                self = .itemNotFound
            case errSecDuplicateItem:
                self = .duplicateItem
            case  errSecMissingEntitlement:
                self = .missingEntitlement
            case errSecParam:
                self = .invalidParams
            default:
                self = .other(status)
            }
        }
    }
    
    /// Executes a keychain operation and translates the result status into a more useful error.
    func execute(_ secOperation: @autoclosure () -> OSStatus) throws(KeychainAPIError) {
        let status = secOperation()
        if let error = KeychainAPIError(status: status) {
            throw error
        }
    }
}


extension KeychainStorage {
    /// An error that occurred while the `KeychainStorage` was trying to perform some operation.
    public enum KeychainError: Error, Sendable {
        /// The keychain was unable to create a `SecAccessControl` object
        case failedToCreateAccessControl(CFError)
        /// The keychain was unable to create a cryptographic key pair
        case failedToCreateKeyPair(CryptographicKeyTag, KeyCreationErrorReason)
        /// A keychain operation failed.
        case other(String)
        
        public enum KeyCreationErrorReason: Sendable {
            /// The key was requested to be created in the secure enclave, but the secure enclave is not available.
            case secureEnclaveNotAvailable
            /// Key pair creation failed, with the specified error.
            case other(CFError)
        }
    }
}


// MARK: Access Control

extension KeychainStorage {
    func addAccessControlFields(for tag: CryptographicKeyTag, to attrs: inout [CFString: Any]) throws(KeychainError) {
        try addAccessControlFields(for: tag.storage, to: &attrs)
    }
    
    
    func addAccessControlFields(for tag: CredentialsTag, to attrs: inout [CFString: Any]) throws(KeychainError) {
        try addAccessControlFields(for: tag.storageOption, to: &attrs)
    }
    
    
    func addAccessControlFields(for storageOption: KeychainItemStorageOption, to attrs: inout [CFString: Any]) throws(KeychainError) {
        // Follows https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility
        
        let protection: CFString // IDEA maybe allow this to be specified via the API? or at least make the API more fine-grained?
        var flags = SecAccessControlCreateFlags()
        
        switch storageOption {
        case .secureEnclave(let requireUserPresence):
            flags.insert(.privateKeyUsage)
            if requireUserPresence {
                protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                flags.insert(.userPresence)
            } else {
                protection = kSecAttrAccessibleAfterFirstUnlock
            }
        case let .keychain(requireUserPresence, accessGroup: _):
            if requireUserPresence {
                protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                flags.insert(.userPresence)
            } else {
                attrs[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                return
            }
        case .keychainSynchronizable:
            attrs[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            return
        }
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, protection, flags, &error) else {
            // SAFETY: the docs say that the error pointer will be populated in the case that the call fails.
            throw .failedToCreateAccessControl(error!.takeRetainedValue()) // swiftlint:disable:this force_unwrapping
        }
        attrs[kSecAttrAccessControl] = accessControl
    }
}
