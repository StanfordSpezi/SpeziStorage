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
/// On the macOS platform, the `SecureStorage` uses the [Data protection keychain](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) which mirrors the data protection keychain originated on iOS.
///
/// ## Topics
/// ### Configuration
/// - ``init()``
///
/// ### Credentials
/// - ``Credentials``
/// - ``store(credentials:server:removeDuplicate:storageScope:)``
/// - ``retrieveCredentials(_:server:accessGroup:)``
/// - ``retrieveAllCredentials(forServer:accessGroup:)``
/// - ``updateCredentials(_:server:newCredentials:newServer:removeDuplicate:storageScope:)``
/// - ``deleteCredentials(_:server:accessGroup:)``
/// - ``deleteAllCredentials(itemTypes:accessGroup:)``
///
/// ### Keys
///
/// - ``createKey(_:size:storageScope:)``
/// - ``retrievePublicKey(forTag:)``
/// - ``retrievePrivateKey(forTag:)``
/// - ``deleteKeys(forTag:)``
@available(*, deprecated, message: "Please use KeyStorage and/or CredentialStorage directly instead.")
public final class SecureStorage: Module, DefaultInitializable, EnvironmentAccessible, Sendable {
    private let credentialStorage = CredentialStorage()
    private let keyStorage = KeyStorage()
    
    /// Configure the SecureStorage module.
    ///
    /// The `SecureStorage` serves as a reusable `Module` that can be used to store store small chunks of data such as credentials and keys.
    ///
    /// - Note: The storing of credentials and keys follows the Keychain documentation provided by Apple:
    /// [Using the keychain to manage user secrets](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets).
    public required init() {}
    
    
    // MARK: - Key Handling
    
    /// Create a `ECSECPrimeRandom` key for a specified size.
    /// - Parameters:
    ///   - tag: The tag used to identify the key in the keychain or the secure enclave.
    ///   - size: The size of the key in bits. The default value is 256 bits.
    ///   - storageScope: The  ``SecureStorageScope`` used to store the newly generate key.
    /// - Returns: Returns the `SecKey` private key generated and stored in the keychain or the secure enclave.
    @discardableResult
    public func createKey(_ tag: String, size: Int = 256, storageScope: SecureStorageScope = .secureEnclave) throws -> SecKey {
        try keyStorage.create(tag, size: size, storageScope: storageScope).privateKey
    }
    
    /// Retrieves a private key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the private `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePrivateKey(forTag tag: String) throws -> SecKey? {
        try keyStorage.retrievePrivateKey(forTag: tag)
    }
    
    /// Retrieves a public key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the public `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePublicKey(forTag tag: String) throws -> SecKey? {
        try keyStorage.retrievePublicKey(forTag: tag)
    }
    
    /// Deletes the key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    public func deleteKeys(forTag tag: String) throws {
        try keyStorage.delete(forTag: tag)
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
        credentials: Credentials,
        server: String? = nil,
        removeDuplicate: Bool = true,
        storageScope: SecureStorageScope = .keychain
    ) throws {
        try credentialStorage.store(
            Credential(
                username: credentials.username,
                password: credentials.password,
                server: server
            ),
            removeDuplicate: removeDuplicate,
            storageScope: storageScope
        )
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
    public func deleteCredentials(_ username: String, server: String? = nil, accessGroup: String? = nil) throws {
        try credentialStorage.delete(username, server: server, accessGroup: accessGroup)
    }
    
    /// Delete all existing credentials stored in the Keychain.
    /// - Parameters:
    ///   - itemTypes: The types of items.
    ///   - accessGroup: The access group associated with the credentials.
    public func deleteAllCredentials(itemTypes: SecureStorageItemTypes = .all, accessGroup: String? = nil) throws {
        try credentialStorage.deleteAll(types: itemTypes, accessGroup: accessGroup)
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
    public func updateCredentials( // swiftlint:disable:this function_default_parameter_at_end
        // The server parameter belongs to the `username` and therefore should be located next to the `username`.
        _ username: String,
        server: String? = nil,
        newCredentials: Credentials,
        newServer: String? = nil,
        removeDuplicate: Bool = true,
        storageScope: SecureStorageScope = .keychain
    ) throws {
        try credentialStorage.update(
            username,
            server: server,
            newCredential: Credential(
                username: newCredentials.username,
                password: newCredentials.password,
                server: newServer
            ),
            removeDuplicate: removeDuplicate,
            storageScope: storageScope
        )
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
    public func retrieveCredentials(_ username: String, server: String? = nil, accessGroup: String? = nil) throws -> Credentials? {
        try credentialStorage.retrieve(username, server: server, accessGroup: accessGroup)
    }
    
    /// Retrieve all existing credentials stored in the Keychain for a specific server.
    /// - Parameters:
    ///   - server: The server associated with the credentials.
    ///   - accessGroup: The access group associated with the credentials.
    /// - Returns: Returns all existing credentials stored in the Keychain identified by the `server` and `accessGroup`.
    public func retrieveAllCredentials(forServer server: String? = nil, accessGroup: String? = nil) throws -> [Credentials] {
        try credentialStorage.retrieveAll(forServer: server, accessGroup: accessGroup)
    }
}
