//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A key identifying entries into the ``CredentialsStorage``.
///
/// This type defines all aspects relevant to how and where a  ``Credentials`` entry is stored into, and fetched from, the ``CredentialsStorage``.
///
/// Example:
/// ```swift
/// extension CredentialsStorageKey {
///     static let accountLogin = CredentialsStorageKey(
///         kind: .internetPassword(server: "stanford.edu"),
///         storageScope: .keychainSynchronizable()
///     )
/// }
///
/// // storing:
/// try credentialsStorage.store(Credentials(username: "lukas", password: "isThisSecure?123"), for: .accountLogin)
///
/// // loading:
/// if let credentials = try credentialsStorage.retrieveCredentials(withUsername: "lukas", forKey: .accountLogin) {
///     // ...
/// }
/// ```
public struct CredentialsStorageKey: Hashable, Sendable {
    /// The kind of the credentials being stored, i.e. whether this is a generic credentials pair, or one associated with some specific website.
    public let kind: CredentialsKind
    /// How exactly the data should be stored.
    public let storageScope: CredentialsStorageScope
    
    /// Creates a new Storage Key.
    private init(kind: CredentialsKind, storageScope: CredentialsStorageScope) {
        self.kind = kind
        self.storageScope = storageScope
    }
    
    /// Creates a new Storage Key for storing an internet password.
    /// - parameter server: The domain name of the server for which this account is.
    /// - parameter scope: How an entry for this key should be persisted using the ``CredentialsStorage``.
    /// - Important: Such credentials cannot be stored in the secure enclave; you must specify one of the keychan options for the storage scope,
    public static func internetPassword(forServer server: String, withScope scope: CredentialsStorageScope = .keychain()) -> Self {
        precondition(!scope.isSecureEnclave, "Storing credentials in the secure enclave is not supported by Apple.")
        return .init(kind: .internetPassword(server: server), storageScope: scope)
    }
    
    /// Creates a new Storage Key for storing a generic password, which is not associated with any particular website or server.
    /// - parameter scope: How an entry for this key should be persisted using the ``CredentialsStorage``.
    /// - Important: Such credentials cannot be stored in the secure enclave; you must specify one of the keychan options for the storage scope,
    public static func genericPassword(withScope scope: CredentialsStorageScope = .keychain()) -> Self {
        precondition(!scope.isSecureEnclave, "Storing credentials in the secure enclave is not supported by Apple.")
        return .init(kind: .genericPassword, storageScope: scope)
    }
}
