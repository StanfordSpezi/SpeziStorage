//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


// swiftlint:disable attributes

import Foundation
import Security


// MARK: Credentials Container


/// How a ``Credentials`` object was populated.
public enum _CredentialsContainerCreationKind: Hashable, Sendable { // swiftlint:disable:this type_name
    /// the credentials object was populated from the results returned form a keychain query
    case keychainQuery
    /// the credentials object was created and populated manually, e.g. via the ``Credentials/init(username:password:)`` initializer.
    case manual
}


/// Internal protocol modeling a container type which represents a keychain-compatible credentials dictionary.
///
/// The `_CredentialsContainer` protocol serves as a unified implementation providing accessor properties
/// for those attributes which are common to both generic and internet password credentials.
///
/// In addition to these accessor properties, it also implements `Hashable` and `Equatable` conformances (based on the underlying attributes),
/// and provides an extension point for adding additional accessors (via `subscript(_:as:)`).
///
/// ## Topics
/// ### Meta-Properties
/// - ``_attributes``
/// - ``_creationKind``
/// - ``kind``
/// - ``asGenericCredentials``
/// - ``asInternetCredentials``
/// ### Credentials Attributes
/// - ``accessControl``
/// - ``accessGroup``
/// - ``accessible``
/// - ``creationDate``
/// - ``modificationDate``
/// - ``description``
/// - ``comment``
/// - ``creator``
/// - ``type``
/// - ``label``
/// - ``isInvisible``
/// - ``isNegative``
/// - ``account``
/// - ``synchronizable``
/// - ``username``
/// - ``password``
public protocol _CredentialsContainer: Hashable, Sendable { // swiftlint:disable:this type_name
    /// The raw attributes of the credentials entry.
    /// - Important: This needs to be public for implementation reasons. Do not access this property directly; instead, always use the respective accessors!
    var _attributes: [CFString: Any] { get set } // swiftlint:disable:this identifier_name
    
    /// How the credentials object was created and populated.
    ///
    /// Based on this value, we can determine whether certain attributes are allowed to be optional, or should be required/expected to exist in the attributes dict.
    /// For example, an interner password will always have a server associated with it,
    /// but this value will typically not be present when the ``Credentials`` object was created via ``Credentials/init(username:password:)``.
    var _creationKind: _CredentialsContainerCreationKind { get } // swiftlint:disable:this identifier_name
    
    /// The underlying ``CredentialsKind``, if known.
    ///
    /// For credentials which are the result of keychain query operations, this value will typically be non-nil.
    ///
    /// - Note: test this: ``asGenericCredentials``
    ///
    /// - Note: this value being nil/non-nil does not necessarily correlate to how the credentials object was created; use refer to `_creationKind` for that.
    var kind: CredentialsKind? { get }
}


extension _CredentialsContainer { // swiftlint:disable:this file_types_order
    /// Compares two `_CredentialsContainer`s for equality, based on the contents of their underlying attributes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs._attributes.keys == rhs._attributes.keys else {
            return false
        }
        return lhs._attributes.allSatisfy { key, lhsVal in
            guard let rhsVal = rhs._attributes[key] else {
                return false
            }
            if let lhsVal = lhsVal as? any Equatable {
                return lhsVal.isEqual(rhsVal)
            } else {
                return CFEqual(lhsVal as CFTypeRef, rhsVal as CFTypeRef)
            }
        }
    }
    
    /// Hashes a `_CredentialsContainer`.
    public func hash(into hasher: inout Hasher) {
        // NOTE: since _attributes typically is a bridged CFDictionary (rather than a native Swift Dictionary),
        // it seems we aren't able to simply compute a hash by iterating over the dict and hashing the key-value pairs.
        // (The issue is that two dictionaries with the same contents apparently might store/iterate them in a different order?)
        // Instead, we match the NSDictionary/CFDictionary behaviour and simply use the number of entries as our hash.
        hasher.combine(_attributes.count)
    }
}


extension _CredentialsContainer { // swiftlint:disable:this file_types_order
    /// Casts the credentials object into a ``GenericCredentials``, if applicable.
    ///
    /// This will return a ``GenericCredentials`` instance if the credentials object represents a "generic password" credentials item.
    /// If the object is an internet password instead, this will return `nil`.
    public var asGenericCredentials: GenericCredentials? {
        switch kind {
        case .genericPassword:
            GenericCredentials(other: self)
        case .internetPassword, nil:
            nil
        }
    }
    
    /// Casts the credentials object into an ``InternetCredentials``, if applicable.
    ///
    /// This will return an ``InternetCredentials`` instance if the credentials object represents an "internet password" credentials item.
    /// If the object is a generic password instead, this will return `nil`.
    public var asInternetCredentials: InternetCredentials? {
        switch kind {
        case .internetPassword:
            InternetCredentials(other: self)
        case .genericPassword, nil:
            nil
        }
    }
}


extension _CredentialsContainer { // swiftlint:disable:this file_types_order
    fileprivate subscript<T>(key: CFString, as _: T.Type = T.self) -> T? {
        get { _attributes[key] as? T }
        set { _attributes[key] = newValue }
    }
}


// MARK: Credentials Types


/// A Credentials pair, consisting of a username, a password, and potentially other fields.
///
/// The ``Credentials`` type models a keychain-compatible credentials pair of unknown type.
/// ``GenericCredentials`` and ``InternetCredentials`` exist as subtypes, and are used to model generic- or internet-password credentials, respectively.
///
/// ## Topics
///
/// ### Creating Credentials
/// - ``init(username:password:)``
///
/// ### Credentials Attributes
/// - ``username``
/// - ``password``
/// - ``account``
/// - ``synchronizable``
/// - ``accessControl``
/// - ``accessGroup``
/// - ``accessible``
/// - ``creationDate``
/// - ``modificationDate``
/// - ``description``
/// - ``comment``
/// - ``creator``
/// - ``type``
/// - ``label``
/// - ``isInvisible``
/// - ``isNegative``
///
/// ### Subtypes
/// - ``kind``
/// - ``GenericCredentials``
/// - ``InternetCredentials``
/// - ``asGenericCredentials``
/// - ``asInternetCredentials``
///
/// ### Other
/// - ``CredentialsKind``
public struct Credentials: _CredentialsContainer, Hashable, @unchecked Sendable { // swiftlint:disable:this file_types_order
    public let _creationKind: _CredentialsContainerCreationKind // swiftlint:disable:this identifier_name
    public var _attributes: [CFString: Any] // swiftlint:disable:this identifier_name
    
    public var kind: CredentialsKind? {
        if let server = self[kSecAttrServer, as: String.self] {
            return .internetPassword(server: server)
        } else if let service = self[kSecAttrService, as: String.self] {
            return .genericPassword(service: service)
        } else {
            return nil
        }
    }
    
    init(_ _attributes: [CFString: Any]) { // swiftlint:disable:this identifier_name
        self._creationKind = .keychainQuery
        self._attributes = _attributes
    }
    
    /// Creates a new credentials object, with the specified username and password
    public init(username: String, password: String) {
        _creationKind = .manual
        _attributes = [:]
        self.username = username
        self.password = password
    }
}


/// A generic (i.e., non-internet) credentials entry from the keychain.
///
/// - Note: "Generic" here does not mean that this is some unknown type of credential; rather, "generic" credentials are those which are not "internet" credentials, i.e., those which are not associated with some specific server.
///
/// ## Topics
/// ### Credentials Attributes
/// -  ``username``
/// -  ``password``
/// -  ``service``
/// -  ``account``
/// - ``synchronizable``
/// - ``accessControl``
/// - ``accessGroup``
/// - ``accessible``
/// - ``creationDate``
/// - ``modificationDate``
/// - ``description``
/// - ``comment``
/// - ``creator``
/// - ``type``
/// - ``label``
/// - ``isInvisible``
/// - ``isNegative``
/// - ``generic``
public struct GenericCredentials: _CredentialsContainer, @unchecked Sendable {
    public let _creationKind: _CredentialsContainerCreationKind // swiftlint:disable:this identifier_name
    public var _attributes: [CFString: Any] // swiftlint:disable:this identifier_name
    
    public var kind: CredentialsKind? {
        .genericPassword(service: service)
    }
    
    init(other: some _CredentialsContainer) {
        _creationKind = other._creationKind
        _attributes = other._attributes
    }
}


/// An internet credentials entry from the keychain.
///
/// Internet credentials are credentials which are associated with some specific server.
/// ## Topics
/// ### Credentials Attributes
/// - ``username``
/// - ``password``
/// - ``server``
/// - ``synchronizable``
/// - ``accessControl``
/// - ``accessGroup``
/// - ``accessible``
/// - ``creationDate``
/// - ``modificationDate``
/// - ``description``
/// - ``comment``
/// - ``creator``
/// - ``type``
/// - ``label``
/// - ``isInvisible``
/// - ``isNegative``
/// - ``account``
/// - ``securityDomain``
/// - ``protocol``
/// - ``authenticationType``
/// - ``port``
/// - ``path``
public struct InternetCredentials: _CredentialsContainer, @unchecked Sendable {
    public let _creationKind: _CredentialsContainerCreationKind // swiftlint:disable:this identifier_name
    public var _attributes: [CFString: Any] // swiftlint:disable:this identifier_name
    
    public var kind: CredentialsKind? {
        .internetPassword(server: server)
    }
    
    init(other: some _CredentialsContainer) {
        _creationKind = other._creationKind
        _attributes = other._attributes
    }
}


// MARK: Credentials Properties

// Properties which are available on both generic and internet password credentials
extension _CredentialsContainer {
    /// The credentials item's `SecAccessControl` definition, if applicable.
    @_documentation(visibility: public)
    public var accessControl: SecAccessControl? {
        self[kSecAttrAccessControl]
    }
    
    /// The keychain access group to which the item belongs, if applicable.
    @_documentation(visibility: public)
    public var accessGroup: String {
        self[kSecAttrAccessGroup] ?? ""
    }
    
    /// The item's accessibilty option, which defines under which circumstances the item can be accessed.
    @_documentation(visibility: public)
    public var accessible: KeychainItemAccessibility? {
        self[kSecAttrAccessible, as: CFString.self]
            .flatMap { .init($0) }
    }
    
    /// The date when the item was added to the keychain, if applicable.
    @_documentation(visibility: public)
    public var creationDate: Date? {
        self[kSecAttrCreationDate]
    }
    
    /// The item's most recent modification date, if applicable.
    @_documentation(visibility: public)
    public var modificationDate: Date? {
        self[kSecAttrModificationDate]
    }
    
    /// The item's user-visible description text, if applicable.
    @_documentation(visibility: public)
    public var description: String? {
        get { self[kSecAttrDescription] }
        set { self[kSecAttrDescription] = newValue }
    }
    
    /// The item's user-visible comment text, if applicable.
    @_documentation(visibility: public)
    public var comment: String? {
        get { self[kSecAttrComment] }
        set { self[kSecAttrComment] = newValue }
    }
    
    /// The item's creator, if applicable.
    ///
    /// This value is a number encoding a four-character code.
    @_documentation(visibility: public)
    public var creator: UInt32? {
        self[kSecAttrCreator]
    }
    
    /// The item's type, if applicable.
    ///
    /// This value is a number encoding a four-character code.
    @_documentation(visibility: public)
    public var type: UInt32? {
        self[kSecAttrType]
    }
    
    /// The item's user-visible label text, if applicable.
    @_documentation(visibility: public)
    public var label: String? {
        get { self[kSecAttrLabel] }
        set { self[kSecAttrLabel] = newValue }
    }
    
    /// Whether the item is invisible, i.e. should not be displayed in e.g. the keychain.
    @_documentation(visibility: public)
    public var isInvisible: Bool {
        self[kSecAttrIsInvisible] == true
    }
    
    /// A key with a value that’s a Boolean indicating whether the item has a valid password.
    @_documentation(visibility: public)
    public var isNegative: Bool {
        self[kSecAttrIsNegative] == true
    }
    
    /// The item's account value, i.e. username.
    @_documentation(visibility: public)
    public var account: String {
        username
    }
    
    /// Whether the item is synchronized across multiple devices belonging to the same user.
    @_documentation(visibility: public)
    public var synchronizable: Bool {
        self[kSecAttrSynchronizable] == true
    }
    
    
    /// The username stored in the Credentials item.
    @_documentation(visibility: public)
    public var username: String {
        get { self[kSecAttrAccount] ?? "" }
        set { self[kSecAttrAccount] = newValue }
    }
    
    /// The password stored in the Credentials item.
    @_documentation(visibility: public)
    public var password: String {
        get { self[kSecValueData, as: Data.self].map { String(decoding: $0, as: UTF8.self) } ?? "" }
        set { self[kSecValueData] = Data(newValue.utf8) }
    }
}


// MARK: "Generic Password" properties

// Properties which are available only on generic credentials
extension GenericCredentials {
    /// The service with which this generic credentials entry is associated.
    @_documentation(visibility: public)
    public var service: String {
        self[kSecAttrService] ?? ""
    }
    
    /// Optional, additional data associated with this item.
    @_documentation(visibility: public)
    public var generic: Data? {
        self[kSecAttrGeneric]
    }
}


// MARK: "Internet Password" properties

// Properties which are available only on internet credentials
extension InternetCredentials {
    /// The item's security domain.
    @_documentation(visibility: public)
    public var securityDomain: String {
        self[kSecAttrSecurityDomain] ?? ""
    }
    
    /// The server (i.e., a website hostname or IP address) associated with this internet credentials entry.
    @_documentation(visibility: public)
    public var server: String {
        self[kSecAttrServer] ?? ""
    }
    
    /// The credentials entry's protocol.
    ///
    /// See [Protocol Values](https://developer.apple.com/documentation/security/item-attribute-keys-and-values#Protocol-Values) for a list of supported values.
    @_documentation(visibility: public)
    public var `protocol`: String? {
        self[kSecAttrProtocol]
    }
    
    /// The credentials entry's authentication type.
    ///
    /// See [Authentication Types](https://developer.apple.com/documentation/security/item-attribute-keys-and-values#Authentication-Type-Values) for a list of supported values.
    @_documentation(visibility: public)
    public var authenticationType: String? {
        self[kSecAttrAuthenticationType]
    }
    
    /// The port associated with this internet credentials entry.
    @_documentation(visibility: public)
    public var port: Int? {
        self[kSecAttrPort]
    }
    
    /// The path associated with this internet credentials entry.
    @_documentation(visibility: public)
    public var path: String? {
        self[kSecAttrPath]
    }
}


// MARK: Utilities

extension Equatable {
    fileprivate func isEqual(_ other: Any) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

// swiftlint:enable attributes
