//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi

public final class CredentialStorage: Module, DefaultInitializable, EnvironmentAccessible, Sendable {
    
    public required init() {}
    
    /// Stores credentials in the Keychain.
    ///
    /// ```swift
    /// do {
    ///     let serverCredentials = Credentials(
    ///         username: "user",
    ///         password: "password"
    ///     )
    ///     try secureStorage.store(
    ///         credentials: serverCredentials,
    ///         server: "stanford.edu",
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
    ///   - server: The server associated with the credentials.
    ///   - removeDuplicate: A flag indicating if any existing key for the `username` and `server`
    ///                      combination should be overwritten when storing the credentials.
    ///   - storageScope: The ``SecureStorageScope`` of the stored credentials.
    ///                   The ``SecureStorageScope/secureEnclave(userPresence:)`` option is not supported for credentials.
    public func store(
        _ credential: Credential,
        server: String? = nil,
        removeDuplicate: Bool = true,
        storageScope: SecureStorageScope = .keychain
    ) throws {
        // This method uses code provided by the Apple Developer documentation at
        // https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain.
        
        assert(!(.secureEnclave ~= storageScope), "Storing of keys in the secure enclave is not supported by Apple.")
        
        var query = queryFor(credential.username, server: server, accessGroup: storageScope.accessGroup)
        query[kSecValueData as String] = Data(credential.password.utf8)
        
        if case .keychainSynchronizable = storageScope {
            query[kSecAttrSynchronizable as String] = true
        } else if let accessControl = try storageScope.accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        do {
            try SecureStorageError.execute(SecItemAdd(query as CFDictionary, nil))
        } catch let SecureStorageError.keychainError(status) where status == -25299 && removeDuplicate {
            try delete(credential.username, server: server)
            try store(credential, server: server, removeDuplicate: false)
        } catch {
            throw error
        }
    }
    
    /// Delete existing credentials stored in the Keychain.
    ///
    /// ```swift
    /// do {
    ///     try secureStorage.deleteCredentials(
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
    ///   - server: The server associated with the credentials.
    ///   - accessGroup: The access group associated with the credentials.
    public func delete(_ username: String, server: String? = nil, accessGroup: String? = nil) throws {
        let query = queryFor(username, server: server, accessGroup: accessGroup)
        
        try SecureStorageError.execute(SecItemDelete(query as CFDictionary))
    }
    
    /// Delete all existing credentials stored in the Keychain.
    /// - Parameters:
    ///   - itemTypes: The types of items.
    ///   - accessGroup: The access group associated with the credentials.
    public func deleteAll(types itemTypes: SecureStorageItemTypes = .all, accessGroup: String? = nil) throws {
        for kSecClassType in itemTypes.kSecClass {
            do {
                var query: [String: Any] = [kSecClass as String: kSecClassType]
                // Only append the accessGroup attribute if the `CredentialsStore` is configured to use KeyChain access groups
                if let accessGroup {
                    query[kSecAttrAccessGroup as String] = accessGroup
                }
                
                // Use Data protection keychain on macOS
                #if os(macOS)
                query[kSecUseDataProtectionKeychain as String] = true
                #endif
                
                try SecureStorageError.execute(SecItemDelete(query as CFDictionary))
            } catch SecureStorageError.notFound {
                // We are fine it no keychain items have been found and therefore non had been deleted.
                continue
            } catch {
                print(error)
            }
        }
    }
    
    /// Update existing credentials found in the Keychain.
    ///
    /// ```swift
    /// do {
    ///     let newCredentials = Credentials(
    ///         username: "user",
    ///         password: "newPassword"
    ///     )
    ///     try secureStorage.updateCredentials(
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
    ///   - username: The username associated with the old credentials.
    ///   - server: The server associated with the old credentials.
    ///   - newCredentials: The new ``Credentials`` that should be stored in the Keychain.
    ///   - newServer: The server associated with the new credentials.
    ///   - removeDuplicate: A flag indicating if any existing key for the `username` of the new credentials and `newServer`
    ///                      combination should be overwritten when storing the credentials.
    ///   - storageScope: The ``SecureStorageScope`` of the newly stored credentials.
    public func update( // swiftlint:disable:this function_default_parameter_at_end
        // The server parameter belongs to the `username` and therefore should be located next to the `username`.
        _ username: String,
        server: String? = nil,
        newCredential: Credential,
        newServer: String? = nil,
        removeDuplicate: Bool = true,
        storageScope: SecureStorageScope = .keychain
    ) throws {
        try delete(username, server: server)
        try store(newCredential, server: newServer, removeDuplicate: removeDuplicate, storageScope: storageScope)
    }
    
    /// Retrieve existing credentials stored in the Keychain.
    ///
    /// ```swift
    /// guard let serverCredentials = secureStorage.retrieveCredentials("user", server: "stanford.edu") else {
    ///     // Handle errors here.
    /// }
    ///
    /// // Use the credentials
    /// ```
    ///
    /// Use ``retrieveAllCredentials(forServer:accessGroup:)`` to retrieve all existing credentials stored in the Keychain for a specific server.
    ///
    /// - Parameters:
    ///   - username: The username associated with the credentials.
    ///   - server: The server associated with the credentials.
    ///   - accessGroup: The access group associated with the credentials.
    /// - Returns: Returns the credentials stored in the Keychain identified by the `username`, `server`, and `accessGroup`.
    public func retrieve(_ username: String, server: String? = nil, accessGroup: String? = nil) throws -> Credential? {
        try retrieveAll(forServer: server, accessGroup: accessGroup)
            .first { $0.username == username }
    }
    
    /// Retrieve all existing credentials stored in the Keychain for a specific server.
    /// - Parameters:
    ///   - server: The server associated with the credentials.
    ///   - accessGroup: The access group associated with the credentials.
    /// - Returns: Returns all existing credentials stored in the Keychain identified by the `server` and `accessGroup`.
    public func retrieveAll(forServer server: String? = nil, accessGroup: String? = nil) throws -> [Credential] {
        // This method uses code provided by the Apple Developer documentation at
        // https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_items
        
        var query: [String: Any] = queryFor(nil, server: server, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        
        var item: CFTypeRef?
        do {
            try SecureStorageError.execute(SecItemCopyMatching(query as CFDictionary, &item))
        } catch SecureStorageError.notFound {
            return []
        } catch {
            throw error
        }
        
        guard let existingItems = item as? [[String: Any]] else {
            throw SecureStorageError.unexpectedCredentialsData
        }
        
        return existingItems.compactMap { existingItem in
            guard let passwordData = existingItem[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8),
                  let account = existingItem[kSecAttrAccount as String] as? String else {
                return nil
            }
            
            return Credential(username: account, password: password)
        }
    }
    
    private func queryFor(_ account: String?, server: String?, accessGroup: String?) -> [String: Any] {
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
        
        // Use Data protection keychain on macOS
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        
        // If the user provided us with a server associated with the credentials we assume it is an internet password.
        if server == nil {
            query[kSecClass as String] = kSecClassGenericPassword
        } else {
            query[kSecClass as String] = kSecClassInternetPassword
            // Only append the server attribute if we assume the credentials to be an internet password.
            query[kSecAttrServer as String] = server
        }
        
        return query
    }
}
