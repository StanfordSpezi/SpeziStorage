//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation
import Spezi

public typealias SecKeyPair = (privateKey: SecKey, publicKey: SecKey)

public final class KeyStorage: Module, DefaultInitializable, EnvironmentAccessible, Sendable {
    
    public required init() {}
    
    // MARK: - Key Handling
    
    /// Create a `ECSECPrimeRandom` key for a specified size.
    /// - Parameters:
    ///   - tag: The tag used to identify the key in the keychain or the secure enclave.
    ///   - size: The size of the key in bits. The default value is 256 bits.
    ///   - storageScope: The  ``SecureStorageScope`` used to store the newly generate key.
    /// - Returns: Returns the `SecKey` private key generated and stored in the keychain or the secure enclave.
    @discardableResult
    public func create(_ tag: String, size: Int = 256, storageScope: SecureStorageScope = .secureEnclave) throws -> SecKeyPair {
        // The key generation code follows
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/protecting_keys_with_the_secure_enclave
        // and
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/generating_new_cryptographic_keys
        
        var privateKeyAttrs: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: Data(tag.utf8)
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
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecureStorageError.createFailed(error?.takeRetainedValue())
        }
        
        return (privateKey, publicKey)
    }
    
    public func retrieveKeyPair(forTag tag: String) throws -> SecKeyPair? {
        guard let privateKey = try retrievePrivateKey(forTag: tag),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            return nil
        }
        
        return (privateKey, publicKey)
    }
    
    /// Retrieves a private key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the private `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePrivateKey(forTag tag: String) throws -> SecKey? {
        // This method follows
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/storing_keys_in_the_keychain
        // for guidance.
        
        var item: CFTypeRef?
        do {
            try SecureStorageError.execute(SecItemCopyMatching(keyQuery(forTag: tag) as CFDictionary, &item))
        } catch SecureStorageError.notFound {
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
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    /// - Returns: Returns the public `SecKey` generated and stored in the keychain or the secure enclave.
    public func retrievePublicKey(forTag tag: String) throws -> SecKey? {
        return try retrieveKeyPair(forTag: tag)?.publicKey
    }
    
    /// Deletes the key stored in the keychain or the secure enclave identified by a `tag`.
    /// - Parameter tag: The tag used to identify the key in the keychain or the secure enclave.
    public func delete(forTag tag: String) throws {
        do {
            try SecureStorageError.execute(SecItemDelete(keyQuery(forTag: tag) as CFDictionary))
        } catch SecureStorageError.notFound {
            return
        } catch {
            throw error
        }
    }
    
    private func keyQuery(forTag tag: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        
        return query
    }
}
