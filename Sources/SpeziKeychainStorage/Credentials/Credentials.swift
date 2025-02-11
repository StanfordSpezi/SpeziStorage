//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
import Security


// MARK: Credentials Container


// A container
public protocol _CredentialsContainer: Hashable, Sendable {
    /// The raw attributes of the credentials entry.
    /// - Important: This needs to be public for implementation reasons. Do not access this property directly; instead, always use the various accessors!
    var _attributes: [CFString: Any] { get set }
    
    init(_ _attributes: [CFString: Any])
    
    var kind: CredentialsKind? { get }
    
    var asGenericCredentials: GenericCredentials? { get }
    var asInternetCredentials: InternetCredentials? { get }
}


extension _CredentialsContainer {
    public func hash(into hasher: inout Hasher) {
        for (key, value) in _attributes {
            hasher.combine(key)
            if let value = value as? any Hashable {
                value.hash(into: &hasher)
            } else {
                // not perfect but the best we got.
                // also not overly bad, since this branch is practically unreachable. (everything we expect to be in the dict is Hashable...)
                let value = value as CFTypeRef
                hasher.combine(CFHash(value))
            }
        }
    }
    
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
}


extension _CredentialsContainer {
    public var kind: CredentialsKind? {
        if let server = self[kSecAttrServer, as: String.self] {
            return .internetPassword(server: server)
        } else if let service = self[kSecAttrService, as: String.self] {
            return .genericPassword(service: service)
        } else {
            return nil
        }
    }
    
    fileprivate subscript<T>(key: CFString, as _: T.Type = T.self) -> T? {
        get { _attributes[key] as? T }
        set { _attributes[key] = newValue }
    }
}



// MARK: Credentials Types


public struct Credentials: _CredentialsContainer, Hashable, @unchecked Sendable {
    public var _attributes: [CFString: Any]
    
    public var asGenericCredentials: GenericCredentials? {
        switch kind {
        case .genericPassword:
            GenericCredentials(_attributes)
        case .internetPassword, nil:
            nil
        }
    }
    
    public var asInternetCredentials: InternetCredentials? {
        switch kind {
        case .internetPassword:
            InternetCredentials(_attributes)
        case .genericPassword, nil:
            nil
        }
    }
    
    public init(_ _attributes: [CFString: Any]) {
        self._attributes = _attributes
    }
    
    public init(username: String, password: String) {
        self.init([:])
        self.username = username
        self.password = password
    }
}



/// A generic (i.e., non-internet) credentials entry from the keychain.
///
/// - Note: "Generic" here does not mean that this is some unknown type of credential; rather, "generic" credentials are those which are not "internet" credentials, i.e., those which are not associated with some specific server.
public struct GenericCredentials: _CredentialsContainer, @unchecked Sendable {
    public var _attributes: [CFString: Any]
    
    public var kind: CredentialsKind? {
        .genericPassword(service: service)
    }
    
    public var asGenericCredentials: GenericCredentials? { self }
    
    public var asInternetCredentials: InternetCredentials? { nil }
    
    public init(_ _attributes: [CFString : Any]) {
        self._attributes = _attributes
    }
}



/// An internet credentials entry from the keychain.
///
/// Internet credentials are credentials which are associated with some specific server.
public struct InternetCredentials: _CredentialsContainer, @unchecked Sendable {
    public var _attributes: [CFString: Any]
    
    public var kind: CredentialsKind? {
        .internetPassword(server: server)
    }
    
    public var asGenericCredentials: GenericCredentials? { nil }
    
    public var asInternetCredentials: InternetCredentials? { self }
    
    public init(_ _attributes: [CFString : Any]) {
        self._attributes = _attributes
    }
}


// MARK: Credentials Properties

// Properties which are available on both types of credentials: generic and internet
extension _CredentialsContainer {
    /// The credentials item's `SecAccessControl` definition, if applicable.
    @_documentation(visibility: public)
    public var accessControl: SecAccessControl? {
        self[kSecAttrAccessControl]
    }
    
    public var accessGroup: String {
        self[kSecAttrAccessGroup]!
    }
    
    public var accessible: KeychainItemAccessibility? {
        self[kSecAttrAccessible, as: CFString.self]
            .flatMap { .init($0) }
    }
    
    public var creationDate: Date? {
        self[kSecAttrCreationDate]
    }
    
    public var modificationDate: Date? {
        self[kSecAttrModificationDate]
    }
    
    public var description: String? {
        get { self[kSecAttrDescription] }
        set { self[kSecAttrDescription] = newValue }
    }
    
    public var comment: String? {
        get { self[kSecAttrComment] }
        set { self[kSecAttrComment] = newValue }
    }
    
    public var creator: UInt32? {
        self[kSecAttrCreator]
    }
    
    public var type: UInt32? {
        self[kSecAttrType]
    }
    
    public var label: String? {
        get { self[kSecAttrLabel] }
        set { self[kSecAttrLabel] = newValue }
    }
    
    public var isInvisible: Bool {
        self[kSecAttrIsInvisible] == kCFBooleanTrue
    }
    
    /// A key with a value that’s a Boolean indicating whether the item has a valid password.
    public var isNegative: Bool {
        self[kSecAttrIsNegative] == kCFBooleanTrue
    }
    
    public var account: String {
        username
    }
    
    public var synchronizable: Bool {
        self[kSecAttrSynchronizable] == kCFBooleanTrue
    }
    
    
    public var username: String {
        get { self[kSecAttrAccount]! }
        set { self[kSecAttrAccount] = newValue }
    }
    
    public var password: String {
        get { self[kSecValueData, as: Data.self].map { String(decoding: $0, as: UTF8.self) }! }
        set { self[kSecValueData] = Data(newValue.utf8) }
    }
}


// Properties which are available only on generic credentials
extension GenericCredentials {
    public var service: String {
        self[kSecAttrService]!
    }
    
    public var generic: Data? {
        self[kSecAttrGeneric]
    }
}


// Properties which are available only on internet credentials
extension InternetCredentials {
    public var securityDomain: String {
        self[kSecAttrSecurityDomain]!
    }
    
    public var server: String {
        self[kSecAttrServer]!
    }
    
    public var `protocol`: String? {
        self[kSecAttrProtocol]
    }
    
    public var authenticationType: String? {
        self[kSecAttrAuthenticationType]
    }
    
    public var port: Int? {
        self[kSecAttrPort]
    }
    
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
