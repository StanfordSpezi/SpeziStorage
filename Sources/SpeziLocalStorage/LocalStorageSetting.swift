//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import Spezi
import SpeziCredentialsStorage


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
    
    
    func keys(from credentialsStorage: CredentialsStorage) throws -> (privateKey: SecKey, publicKey: SecKey)? {
        let storageScope: CredentialsStorageScope
        switch self {
        case .unencrypted:
            return nil
        case let .encrypted(privateKey, publicKey, _):
            return (privateKey, publicKey)
        case let .encryptedUsingSecureEnclave(userPresence):
            storageScope = .secureEnclave(userPresence: userPresence)
        case let .encryptedUsingKeyChain(userPresence, _):
            storageScope = .keychain(userPresence: userPresence)
        }
        
        let keyTag = KeyTag("LocalStorage.\(storageScope.id)")
        
        if let privateKey = try? credentialsStorage.retrievePrivateKey(for: keyTag),
           let publicKey = try? credentialsStorage.retrievePublicKey(for: keyTag) {
            return (privateKey, publicKey)
        }
        
        let privateKey = try credentialsStorage.createKey(for: keyTag)
        guard let publicKey = try credentialsStorage.retrievePublicKey(for: keyTag) else {
            throw LocalStorageError.encryptionNotPossible
        }
        
        return (privateKey, publicKey)
    }
}
