//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Security


extension SecKey {
    /// The key's "simple" attributes, as returned from `SecKeyCopyAttributes`.
    private var simpleAttributes: [String: Any]? {
        SecKeyCopyAttributes(self) as? [String: Any]
    }
    
    /// The key's "extended" attributes, as returned from `SecItemCopyMatching`.
    private var extendedAttributes: [String: Any]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: self,
            kSecReturnAttributes as String: true
        ]
        var attrs: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &attrs)
        return status == errSecSuccess ? attrs as? [String: Any] : nil
    }
    
    
    private func readSimpleAttr<R>(_ key: CFString, as _: R.Type = R.self) -> R? {
        simpleAttributes?[key as String] as? R
    }
    
    private func readExtendedAttr<R>(_ key: CFString, as _: R.Type = R.self) -> R? {
        extendedAttributes?[key as String] as? R
    }
    
    /// Fetches or computes a private key's corresponding public key.
    public var publicKey: SecKey? {
        SecKeyCopyPublicKey(self)
    }
    
    public var applicationTag: String? {
        readExtendedAttr(kSecAttrApplicationTag, as: Data.self).flatMap { String(data: $0, encoding: .utf8) }
    }
    
    public var applicationLabel: Data? {
        readSimpleAttr(kSecAttrApplicationLabel)
    }
    
    /// The key's `kSecAttrLabel` value, i.e. its user-visible label.
    public var label: String? {
        readExtendedAttr(kSecAttrLabel)
    }
    
    public var keyType: String? {
        readSimpleAttr(kSecAttrKeyType)
    }
    
    public var keyClass: KeychainStorage.KeyClass? {
        readSimpleAttr(kSecAttrKeyClass, as: CFString.self)
            .flatMap { .init($0) }
    }
    
    /// Whether the `SecKey` represents a public key.
    public var isPublicKey: Bool {
        keyClass == .public
    }
    
    /// Whether the `SecKey` represents a private key.
    public var isPrivateKey: Bool {
        keyClass == .private
    }
    
    /// The `SecKey`'s access group, if applicable.
    public var accessGroup: String? {
        readExtendedAttr(kSecAttrAccessGroup)
    }
    
    /// The `SecKey`'s size, in bit
    public var sizeInBits: Int? {
        readSimpleAttr(kSecAttrKeySizeInBits)
    }
    
    /// The `SecKey`'s access control specification, if applicable
    public var accessControl: SecAccessControl? {
        readExtendedAttr(kSecAttrAccessControl)
    }
    
    /// When the `SecKey` is accessible
    public var accessible: KeychainItemAccessibility? {
        readExtendedAttr(kSecAttrAccessible, as: CFString.self)
            .flatMap { .init($0) }
    }
    
    /// Whether the `SecKey` is permanently persisted to either the keychain or the secure enclave
    public var isPermanent: Bool? {
        readExtendedAttr(kSecAttrIsPermanent)
    }
    
    /// The `SecKey`'s effective size, in bits
    public var effectiveKeySize: Int? {
        return readExtendedAttr(kSecAttrEffectiveKeySize)
    }
    
    /// Whether the `SecKey` can be used for encryption
    public var canEncrypt: Bool? {
        readSimpleAttr(kSecAttrCanEncrypt)
    }
    
    /// Whether the `SecKey` can be used for decryption
    public var canDecrypt: Bool? {
        readSimpleAttr(kSecAttrCanDecrypt)
    }
    
    /// Whether the `SecKey` can be used for derivation
    public var canDerive: Bool? {
        readSimpleAttr(kSecAttrCanDerive)
    }
    
    /// Whether the `SecKey` can be used for signing
    public var canSign: Bool? {
        readSimpleAttr(kSecAttrCanSign)
    }
    
    /// Whether the `SecKey` can be used for signature verification
    public var canVerify: Bool? {
        readSimpleAttr(kSecAttrCanVerify)
    }
    
    /// Whether the `SecKey` can be used for wrapping
    public var canWrap: Bool? {
        readExtendedAttr(kSecAttrCanWrap)
    }
    
    /// Whether the `SecKey` can be used for unwrapping
    public var canUnwrap: Bool? {
        readExtendedAttr(kSecAttrCanUnwrap)
    }
    
    /// Whether the `SecKey` is synchronizable.
    public var synchronizable: Bool {
        readExtendedAttr(kSecAttrSynchronizable) == kCFBooleanTrue
    }
    
    /// Whether the `SecKey` is stored in an external location (i.e, outside of the keychain), and if yes in which location it is stored.
    public var tokenId: KeychainItemTokenID? {
        readSimpleAttr(kSecAttrTokenID, as: CFString.self)
            .flatMap { .init($0) }
    }
}


/// Specifies a keychain item's external storage location, if any.
public enum KeychainItemTokenID: Hashable, Sendable {
    /// The keychain item is stored in the secure enclave.
    case secureEnclave
    
    /// Creates a `KeychainItemTokenID` from its underlying `CFString` value.
    public init?(_ rawValue: CFString) {
        switch rawValue {
        case kSecAttrTokenIDSecureEnclave:
            self = .secureEnclave
        default:
            return nil
        }
    }
    
    /// The underlying `CFString` value.
    public var rawValue: CFString {
        switch self {
        case .secureEnclave:
            kSecAttrTokenIDSecureEnclave
        }
    }
}
