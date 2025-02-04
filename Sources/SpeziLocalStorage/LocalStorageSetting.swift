//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import Spezi
import SpeziSecureStorage


/// Configure how data is encrypyed, stored, and retrieved.
public enum LocalStorageSetting {
    /// Unencrypted
    case unencrypted(excludeFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key: private key for encryption and a public key for decryption.
    case encrypted(privateKey: SecKey, publicKey: SecKey, excludeFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Secure Enclave.
    case encryptedUsingSecureEnclave(userPresence: Bool = false)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Keychain.
    case encryptedUsingKeyChain(userPresence: Bool = false, excludeFromBackup: Bool = true)
    
    
    var isExcludedFromBackup: Bool {
        switch self {
        case let .unencrypted(excludeFromBackup),
             let .encrypted(_, _, excludeFromBackup),
             let .encryptedUsingKeyChain(_, excludeFromBackup):
            return excludeFromBackup
        case .encryptedUsingSecureEnclave:
            return true
        }
    }
    
    
    func keys(from secureStorage: SecureStorage) throws -> (privateKey: SecKey, publicKey: SecKey)? {
        let secureStorageScope: SecureStorageScope
        switch self {
        case .unencrypted:
            return nil
        case let .encrypted(privateKey, publicKey, _):
            return (privateKey, publicKey)
        case let .encryptedUsingSecureEnclave(userPresence):
            secureStorageScope = .secureEnclave(userPresence: userPresence)
        case let .encryptedUsingKeyChain(userPresence, _):
            secureStorageScope = .keychain(userPresence: userPresence)
        }
        
        let tag = "LocalStorage.\(secureStorageScope.id)"
        
        if let privateKey = try? secureStorage.retrievePrivateKey(forTag: tag),
           let publicKey = try? secureStorage.retrievePublicKey(forTag: tag) {
            return (privateKey, publicKey)
        }
        
        let privateKey = try secureStorage.createKey(tag)
        guard let publicKey = try secureStorage.retrievePublicKey(forTag: tag) else {
            throw LocalStorageError.encryptionNotPossible
        }
        
        return (privateKey, publicKey)
    }
}
