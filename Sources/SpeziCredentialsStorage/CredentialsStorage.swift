//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation
import LocalAuthentication
import Security
import Spezi
import XCTRuntimeAssertions


/// Securely store small chunks of data such as credentials and keys.
///
/// The storing of credentials and keys follows the Keychain documentation provided by Apple: 
/// [Using the keychain to manage user secrets](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets).
///
/// On the macOS platform, the `CredentialsStorage` uses the [Data protection keychain](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) which mirrors the data protection keychain originated on iOS.
///
/// ## Topics
/// ### Configuration
/// - ``init()``
///
/// ### Credential Storage
/// - ``Credentials``
/// - ``store(_:for:removeDuplicate:)``
/// - ``retrieveCredentials(withUsername:forKey:)``
/// - ``retrieveAllCredentials(for:)``
/// - ``updateCredentials(forUsername:key:with:removeDuplicate:)``
/// - ``deleteKeys(for:)``
/// - ``deleteAllCredentials(itemTypes:accessGroup:)``
///
/// ### Key Storage
/// - ``createKey(for:size:storageScope:)``
/// - ``retrievePublicKey(for:)``
/// - ``retrievePrivateKey(for:)``
/// - ``deleteKeys(for:)``
///
/// ### Other
/// - ``CredentialsKind``
/// - ``CredentialsStorageScope``
/// - ``CredentialsStorageError``
/// - ``CredentialsStorageItemTypes``
public final class CredentialsStorage: Module, DefaultInitializable, EnvironmentAccessible, Sendable {
    /// Configure the `CredentialsStorage` module.
    ///
    /// The `CredentialsStorage` serves as a reusable `Module` that can be used to store store small chunks of data such as credentials and keys.
    ///
    /// - Note: The storing of credentials and keys follows the Keychain documentation provided by Apple:
    /// [Using the keychain to manage user secrets](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets).
    public required init() {}
    
    
    // MARK: - Key Handling
    
    /// Create a `ECSECPrimeRandom` key for a specified size.
    /// - Parameters:
    ///   - keyTag: The tag used to identify the key in the keychain or the secure enclave.
    ///   - size: The size of the key in bits. The default value is 256 bits.
    ///   - storageScope: The  ``CredentialsStorageScope`` used to store the newly generate key.
    /// - Returns: Returns the `SecKey` private key generated and stored in the keychain or the secure enclave.
    @discardableResult
    public func createKey(for keyTag: KeyTag, size: Int = 256, storageScope: CredentialsStorageScope = .secureEnclave()) throws -> SecKey {
        // The key generation code follows
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/protecting_keys_with_the_secure_enclave
        // and
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/generating_new_cryptographic_keys
        
        var privateKeyAttrs: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: Data(keyTag.rawValue.utf8)
        ]
        if let accessControl = try storageScope.accessControl {
            privateKeyAttrs[kSecAttrAccessControl as String] = accessControl
        }
        
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: size as CFNumber,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: privateKeyAttrs
        ]
        
        // Use Data protection keychain on macOS
        #if os(macOS)
        attributes[kSecUseDataProtectionKeychain as String] = true
        #endif
        
        // Check that the device has a Secure Enclave
        if SecureEnclave.isAvailable {
            // Generate private key in Secure Enclave
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              SecKeyCopyPublicKey(privateKey) != nil else {
            throw CredentialsStorageError.createFailed(error?.takeRetainedValue())
        }
        
        return privateKey
    }
    
    
    /// Retrieves a private key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the private `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePrivateKey(for keyTag: KeyTag) throws -> SecKey? {
        // This method follows
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/storing_keys_in_the_keychain
        // for guidance.
        var item: CFTypeRef?
        do {
            try execute(SecItemCopyMatching(keyQuery(for: keyTag) as CFDictionary, &item))
        } catch CredentialsStorageError.notFound {
            return nil
        } catch {
            throw error
        }
        // Unfortunately we have to do a force cast here.
        // The compiler complains that "Conditional downcast to CoreFoundation type 'SecKey' will always succeed"
        // if we use `item as? SecKey`.
        return (item as! SecKey) // swiftlint:disable:this force_cast
    }
    
    
    /// Retrieves a public key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the public `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePublicKey(for keyTag: KeyTag) throws -> SecKey? {
        if let privateKey = try retrievePrivateKey(for: keyTag) {
            return SecKeyCopyPublicKey(privateKey)
        } else {
            return nil
        }
    }
    
    
    /// Deletes the key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter keyTag: The tag used to identify the key in the keychain or the secure enclave.
    public func deleteKeys(for keyTag: KeyTag) throws {
        do {
            try execute(SecItemDelete(keyQuery(for: keyTag) as CFDictionary))
        } catch CredentialsStorageError.notFound {
            return
        } catch {
            throw error
        }
    }
    
    
    private func keyQuery(for keyTag: KeyTag) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag.rawValue,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        return query
    }
    
    
    // MARK: - Credentials Handling
    
    /// Stores credentials in the Keychain.
    ///
    /// ```swift
    /// do {
    ///     let serverCredentials = Credentials(
    ///         username: "user",
    ///         password: "password"
    ///     )
    ///     try credentialsStorage.store(
    ///         credentials: serverCredentials,
    ///         ofKind: .internetPassword("stanford.edu"),
    ///         storageScope: .keychainSynchronizable
    ///     )
    ///
    ///     // ...
    ///
    /// } catch {
    ///     // Handle creation error here.
    ///     // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - credentials: The ``Credentials`` stored in the Keychain.
    ///   - key: The key identifying the credentials entry.
    ///   - removeDuplicate: A flag indicating if any existing key for the `username` and `credentialsKind`
    ///                      combination should be overwritten when storing the credentials.
    public func store(
        _ credentials: Credentials,
        for key: CredentialsStorageKey,
        removeDuplicate: Bool = true
    ) throws {
        // This method uses code provided by the Apple Developer documentation at
        // https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain.
        
        var query = queryFor(username: credentials.username, key: key)
        query[kSecValueData as String] = Data(credentials.password.utf8)
        
        if case .keychainSynchronizable = key.storageScope {
            query[kSecAttrSynchronizable as String] = true
        } else if let accessControl = try key.storageScope.accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        do {
            try execute(SecItemAdd(query as CFDictionary, nil))
        } catch CredentialsStorageError.keychainError(-25299) where removeDuplicate {
            try deleteCredentials(withUsername: credentials.username, for: key)
            try store(credentials, for: key, removeDuplicate: false)
        } catch {
            throw error
        }
    }
    
    
    /// Delete existing credentials stored in the Keychain.
    ///
    /// ```swift
    /// do {
    ///     try credentialsStorage.deleteCredentials(
    ///         "user",
    ///         server: "spezi.stanford.edu"
    ///     )
    /// } catch {
    ///     // Handle deletion error here.
    ///     // ...
    /// }
    /// ```
    ///
    /// Use to ``deleteAllCredentials(itemTypes:accessGroup:)`` delete all existing credentials stored in the Keychain.
    ///
    /// - Parameters:
    ///   - username: The username associated with the credentials.
    ///   - key: The key identifying the credentials entry.
    public func deleteCredentials(withUsername username: String, for key: CredentialsStorageKey) throws {
        let query = queryFor(username: username, key: key)
        try execute(SecItemDelete(query as CFDictionary))
    }
    
    
    /// Delete all existing credentials stored in the Keychain.
    /// - Parameters:
    ///   - itemTypes: The types of items.
    ///   - accessGroup: The access group associated with the credentials.
    public func deleteAllCredentials(itemTypes: CredentialsStorageItemTypes = .all, accessGroup: String? = nil) throws {
        for kSecClassType in itemTypes.kSecClass {
            do {
                var query: [String: Any] = [
                    kSecClass as String: kSecClassType,
                    kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
                ]
                // Only append the accessGroup attribute if the `CredentialsStore` is configured to use KeyChain access groups
                if let accessGroup {
                    query[kSecAttrAccessGroup as String] = accessGroup
                }
                // Use Data protection keychain on macOS
                #if os(macOS)
                query[kSecUseDataProtectionKeychain as String] = true
                #endif
                try execute(SecItemDelete(query as CFDictionary))
            } catch CredentialsStorageError.notFound {
                // We are fine it no keychain items have been found and therefore non had been deleted.
                continue
            } catch {
                throw error
            }
        }
    }
    
    
    /// Update existing credentials associated with a specific ``CredentialsStorageKey``.
    ///
    /// Use this function if you want to update e.g. the username or password of an entry in the ``CredentialsStorage``.
    ///
    /// - Note: Do not use this function if you want to change the server address associated with a stored credentials entry. In that case, simply delete the old entry and create a new one.
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let newCredentials = Credentials(
    ///         username: "user",
    ///         password: "newPassword"
    ///     )
    ///     try credentialsStorage.updateCredentials(
    ///         "user",
    ///         server: "stanford.edu",
    ///         newCredentials: newCredentials,
    ///         newServer: "spezi.stanford.edu"
    ///     )
    /// } catch {
    ///     // Handle update error here.
    ///     // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - oldUsername: The username associated with the old credentials.
    ///   - key: Key identifying the credentials entry.
    ///   - newCredentials: The new ``Credentials`` that should be stored in the Keychain.
    ///   - removeDuplicate: A flag indicating if any existing key for the `username` of the new credentials and `newServer`
    ///                      combination should be overwritten when storing the credentials.
    public func updateCredentials(
        forUsername oldUsername: String,
        key: CredentialsStorageKey,
        with newCredentials: Credentials,
        removeDuplicate: Bool = true
    ) throws {
        try deleteCredentials(withUsername: oldUsername, for: key)
        try store(newCredentials, for: key, removeDuplicate: removeDuplicate)
    }
    
    
    /// Retrieve existing credentials stored in the Keychain.
    ///
    /// ```swift
    /// guard let serverCredentials = credentialsStorage.retrieveCredentials("user", server: "stanford.edu") else {
    ///     // Handle errors here.
    /// }
    ///
    /// // Use the credentials
    /// ```
    ///
    /// Use ``retrieveAllCredentials(for:)`` to retrieve all existing credentials stored in the Keychain for a specific server.
    ///
    /// - Parameters:
    ///   - username: The username associated with the credentials.
    ///   - key: The key identifying the credentials.
    /// - Returns: Returns the first ``Credentials`` stored in the Keychain identified by `key`, matching `username`.
    public func retrieveCredentials(withUsername username: String, forKey key: CredentialsStorageKey) throws -> Credentials? {
        try retrieveAllCredentials(for: key).first { $0.username == username }
    }
    
    
    /// Retrieve all existing credentials stored in the Keychain for a specific server.
    /// - parameter key: the key identifying the credentials which should be retrieved.
    /// - Returns: Returns all existing credentials stored in the Keychain identified by `key`.
    public func retrieveAllCredentials(for key: CredentialsStorageKey) throws -> [Credentials] {
        // This method uses code provided by the Apple Developer documentation at
        // https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_items
        var query: [String: Any] = queryFor(username: nil, key: key)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var item: CFTypeRef?
        do {
            try execute(SecItemCopyMatching(query as CFDictionary, &item))
        } catch CredentialsStorageError.notFound {
            return []
        } catch {
            throw error
        }
        guard let existingItems = item as? [[String: Any]] else {
            throw CredentialsStorageError.unexpectedCredentialsData
        }
        var credentials: [Credentials] = []
        for existingItem in existingItems {
            guard let passwordData = existingItem[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8),
                  let account = existingItem[kSecAttrAccount as String] as? String else {
                continue
            }
            credentials.append(Credentials(username: account, password: password))
        }
        return credentials
    }
    
    
    public func retrieveAllCredentials(ofType itemTypes: CredentialsStorageItemTypes) throws -> [Credentials] {
        var results: [Credentials] = []
        var query: [String: Any] = [
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        for cls in itemTypes.kSecClass {
            query[kSecClass as String] = cls as String
            var items: CFTypeRef?
            do {
                try execute(SecItemCopyMatching(query as CFDictionary, &items))
            } catch CredentialsStorageError.notFound {
                continue
            } catch {
                throw error
            }
            guard let items = items as? [[String: Any]] else {
                throw CredentialsStorageError.unexpectedCredentialsData
            }
            for item in items {
                guard let account = item[kSecAttrAccount as String] as? String,
                      let password = item[kSecValueData as String] as? Data,
                      let password = String(data: password, encoding: .utf8) else {
                    continue
                }
                results.append(.init(username: account, password: password))
            }
        }
        return results
    }
    
    
    private func execute(_ secOperation: @autoclosure () -> OSStatus) throws {
        switch secOperation() {
        case errSecSuccess:
            // it's fine
            return
        case errSecItemNotFound:
            throw CredentialsStorageError.notFound
        case  errSecMissingEntitlement:
            throw CredentialsStorageError.missingEntitlement
        case let status:
            throw CredentialsStorageError.keychainError(status: status)
        }
    }
    
    
    private func queryFor(username: String?, key: CredentialsStorageKey) -> [String: Any] {
        queryFor(
            username: username,
            kind: key.kind,
            synchronizable: key.storageScope.isSynchronizable,
            accessGroup: key.storageScope.accessGroup
        )
    }
    
    
    /// - parameter synchronizable: defines how the query should filter items based on their synchronizability.
    ///     if you pass `nil` for this parameter, the query will match both synchronizable and non-synchroniable entries.
    ///     if you pass `true` or `false`, the query will match only those entries whose synchronizability matches the param value.
    private func queryFor(
        username account: String?,
        kind: CredentialsKind,
        synchronizable: Bool?, // swiftlint:disable:this discouraged_optional_boolean
        accessGroup: String?
    ) -> [String: Any] {
        // This method uses code provided by the Apple Developer documentation at
        // https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets
        
        var query: [String: Any] = [:]
        if let account {
            query[kSecAttrAccount as String] = account
        }
        
        // Only append the accessGroup attribute if the `CredentialsStore` is configured to use KeyChain access groups
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        switch synchronizable {
        case .none:
            // if the `synchronizable` parameter is set to nil, we do not filter for this field, and instead wanna fetch all entried (both synchronizable and non-synchronizable)
            query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        case .some(let value):
            // if the parameter is set, we want to filter for that value
            query[kSecAttrSynchronizable as String] = value
        }
        
        // Use Data protection keychain on macOS
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        
        // If the user provided us with a server associated with the credentials we assume it is an internet password.
        switch kind {
        case .genericPassword:
            query[kSecClass as String] = kSecClassGenericPassword
        case .internetPassword(let server):
            query[kSecClass as String] = kSecClassInternetPassword
            // Only append the server attribute if we assume the credentials to be an internet password.
            query[kSecAttrServer as String] = server
        }
        
        return query
    }
}
