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


extension KeychainStorage {
    public enum KeyClass: Hashable, Sendable, CustomDebugStringConvertible {
        case `private`
        case `public`
        case symmetric
        
        public init?(_ rawValue: CFString) {
            switch rawValue {
            case kSecAttrKeyClassPrivate:
                self = .private
            case kSecAttrKeyClassPublic:
                self = .public
            case kSecAttrKeyClassSymmetric:
                self = .symmetric
            default:
                return nil
            }
        }
        
        public var rawValue: CFString {
            switch self {
            case .private: kSecAttrKeyClassPrivate
            case .public: kSecAttrKeyClassPublic
            case .symmetric: kSecAttrKeyClassSymmetric
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .private: "private"
            case .public: "public"
            case .symmetric: "symmetric"
            }
        }
    }
    
    
    /// Create a `ECSECPrimeRandom` key for a specified size.
    /// - Parameters:
    ///   - keyTag: The tag used to define the key in the keychain or the secure enclave, and for key creation purposes.
    /// - Returns: Returns the `SecKey` private key generated and stored in the keychain or the secure enclave.
    @discardableResult
    public func createKey(for keyTag: CryptographicKeyTag) throws -> SecKey {
        // The key generation code follows
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/protecting_keys_with_the_secure_enclave
        // and
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/generating_new_cryptographic_keys
        
        let privateKeyAttrs: [CFString: Any] = try { () -> [CFString: Any] in
            var attrs: [CFString: Any] = [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: Data(keyTag.tagValue.utf8) as CFData
            ]
            if let label = keyTag.label {
                attrs[kSecAttrLabel] = label as CFString
            }
            try addAccessControlFields(for: keyTag, to: &attrs)
            if let accessGroup = keyTag.storage.accessGroup {
                attrs[kSecAttrAccessGroup] = accessGroup as CFString
            }
            if keyTag.storage.isSynchronizable {
                attrs[kSecAttrSynchronizable] = true
            }
            return attrs
        }()
        
        var attributes: [CFString: Any] = [
            kSecAttrKeyType: keyTag.keyType,
            kSecAttrKeySizeInBits: keyTag.size as CFNumber,
            kSecPrivateKeyAttrs: privateKeyAttrs,
            kSecUseDataProtectionKeychain: true
        ]
        
        // Check that the device has a Secure Enclave
        switch (keyTag.storage.isSecureEnclave, SecureEnclave.isAvailable) {
        case (true, true):
            attributes[kSecAttrTokenID] = kSecAttrTokenIDSecureEnclave
        case (false, _):
            break
        case (true, false):
            throw KeychainError.failedToCreateKeyPair(.secureEnclaveNotAvailable)
        }
        
        var error: Unmanaged<CFError>?
        if let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
            return privateKey
        } else {
            // SAFETY: the force unwrap here is ok,
            // since it's guaranteed that the error will be non-nil if the SecKeyCreateRandomKey retval was.
            let error = error!.takeRetainedValue() // swiftlint:disable:this force_unwrapping
            throw KeychainError.failedToCreateKeyPair(.other(error))
        }
    }
    
    
    // MARK: Key Retrieval
    
    /// Retrieves a private key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the private `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePrivateKey(for keyTag: CryptographicKeyTag) throws -> SecKey? {
        try retrieveKey(.private, for: keyTag)
    }
    
    
    /// Retrieves a public key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the public `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePublicKey(for keyTag: CryptographicKeyTag) throws -> SecKey? {
        try retrieveKey(.public, for: keyTag)
    }
    
    
    private func retrieveKey(_ keyClass: KeyClass, for tag: CryptographicKeyTag) throws -> SecKey? { // swiftlint:disable:this cyclomatic_complexity
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: Data(tag.tagValue.utf8),
            kSecAttrKeyType: tag.keyType,
            kSecReturnRef: true,
            kSecUseDataProtectionKeychain: true
        ]
        switch tag.storage {
        case .secureEnclave:
            break
        case .keychain(requireUserPresence: _, let accessGroup):
            if let accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
        case .keychainSynchronizable(let accessGroup):
            query[kSecAttrSynchronizable] = true
            if let accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
        }
        var item: CFTypeRef?
        do {
            try execute(SecItemCopyMatching(query as CFDictionary, &item))
        } catch .itemNotFound {
            switch keyClass {
            case .public:
                // if we're unable to find the public key, we instead try to retrieve the private key and reconstruct the public key.
                return try retrieveKey(.private, for: tag).flatMap(SecKeyCopyPublicKey)
            case .private, .symmetric:
                // we obviously can't reconstruct the private key from the public key, so there's nothing we can do here.
                return nil
            }
        } catch {
            throw error
        }
        guard let item = item.map({ unsafeDowncast($0, to: SecKey.self) }) else {
            throw KeychainError.other("Unable to cast CFTypeRef to SecKey")
        }
        switch keyClass {
        case .private, .symmetric:
            return item
        case .public:
            return SecKeyCopyPublicKey(item)
        }
    }
    
    
    /// Retrieves all keys of the specified key class belonging to the specified access group
    public func retrieveAllKeys(_ keyClass: KeyClass, accessGroup: AccessGroupFilter = .any) throws -> [SecKey] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: keyClass.rawValue,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        if let accessGroup = accessGroup.stringValue {
            query[kSecAttrAccessGroup ] = accessGroup
        }
        var items: CFTypeRef?
        do {
            try execute(SecItemCopyMatching(query as CFDictionary, &items))
        } catch .itemNotFound {
            return []
        } catch {
            throw error
        }
        guard let items = items as? [SecKey] else {
            throw KeychainError.other("Unable to fetch keys")
        }
        return items
    }
    
    
    /// Deletes the key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    public func deleteKey(for keyTag: CryptographicKeyTag) throws {
        if let key = try retrievePrivateKey(for: keyTag) {
            try deleteKey(key)
        }
    }
    
    
    /// Deletes a key from the keychain or secure enclave
    /// - parameter key: The `SecKey` which should be deleted.
    public func deleteKey(_ key: SecKey) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            // for some reason, deleting a synchronizable key won't work (and fail with .itemNotFound) unless we specify this,
            // which is weird since you'd expect the fact that we specify the key directly would be sufficient for the API to find it.
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecValueRef: key
        ]
        do {
            try execute(SecItemDelete(query as CFDictionary))
        } catch .itemNotFound {
            return
        } catch {
            throw error
        }
    }
    
    
    /// Deletes all keys from the keychain.
    public func deleteAllKeys(accessGroup: AccessGroupFilter) throws {
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        if let accessGroup = accessGroup.stringValue {
            query[kSecAttrAccessGroup ] = accessGroup
        }
        do {
            try execute(SecItemDelete(query as CFDictionary))
        } catch .itemNotFound {
            return
        } catch {
            throw error
        }
    }
}
