//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A key identifying entries into the ``KeychainStorage``.
///
/// This type defines all aspects relevant to how and where a  ``Credentials`` entry is stored into, and fetched from, the ``KeychainStorage``.
///
/// Example:
/// ```swift
/// extension CredentialsTag {
///     static let stanfordSUNet = Self.internetPassword(
///         forServer: "stanford.edu",
///         storage: .keychainSynchronizable
///     )
/// }
///
/// // storing:
/// try keychainStorage.store(Credentials(username: "lukas", password: "isThisSecure?123"), for: .stanfordSUNet)
///
/// // loading:
/// if let credentials = try keychainStorage.retrieveCredentials(withUsername: "lukas", for: .stanfordSUNet) {
///     // ...
/// }
/// ```
public struct CredentialsTag: Hashable, Sendable {
    /// The kind of the credentials being stored, i.e. whether this is a generic credentials pair, or one associated with some specific website.
    public let kind: CredentialsKind
    /// How exactly the data should be stored.
    public let storageOption: KeychainItemStorageOption
    /// The credentials' label.
    ///
    /// When storing credentials using ``KeychainStorage/store(_:for:replaceDuplicates:)``, this value is used for `kSecAttrLabel`,
    /// unless the ``Credentials`` being stored specify a label value of their own.
    public let label: String?
    
    /// Creates a new Storage Key.
    private init(kind: CredentialsKind, storage: KeychainItemStorageOption, label: String?) {
        self.kind = kind
        self.storageOption = storage
        self.label = label
    }
    
    /// Creates a new Storage Key for storing an internet password.
    /// - parameter server: The domain name of the server for which this account is.
    /// - parameter storage: How an entry for this key should be persisted using the ``KeychainStorage``.
    /// - Important: Such credentials cannot be stored in the secure enclave; you must specify one of the keychan options for the storage scope,
    public static func internetPassword(
        forServer server: String,
        storage: KeychainItemStorageOption = .keychain(requireUserPresence: false, accessGroup: nil),
        label: String? = nil
    ) -> Self {
        precondition(!storage.isSecureEnclave, "Storing credentials in the secure enclave is not supported.")
        return .init(kind: .internetPassword(server: server), storage: storage, label: label)
    }
    
    /// Creates a new Storage Key for storing a generic password, which is not associated with any particular website or server.
    /// - parameter storage: How an entry for this key should be persisted using the ``KeychainStorage``.
    /// - Important: Such credentials cannot be stored in the secure enclave; you must specify one of the keychan options for the storage scope,
    public static func genericPassword(
        forService service: String,
        storage: KeychainItemStorageOption = .keychain(requireUserPresence: false, accessGroup: nil),
        label: String? = nil
    ) -> Self {
        precondition(!storage.isSecureEnclave, "Storing credentials in the secure enclave is not supported.")
        return .init(kind: .genericPassword(service: service), storage: storage, label: label)
    }
}
