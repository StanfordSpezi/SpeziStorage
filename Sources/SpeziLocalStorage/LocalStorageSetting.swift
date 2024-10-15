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


/// Configure how data can be stored and retrieved.
public enum LocalStorageSetting {
    /// Unencrypted
    case unencrypted(excludedFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key: private key for encryption and a public key for decryption.
    case encrypted(keys: SecKeyPair, excludedFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Secure Enclave.
    case encryptedUsingSecureEnclave(userPresence: Bool = false)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Keychain.
    case encryptedUsingKeyChain(userPresence: Bool = false, excludedFromBackup: Bool = true)
    
    var excludedFromBackup: Bool {
        switch self {
        case let .unencrypted(excludedFromBackup),
             let .encrypted(_, excludedFromBackup),
             let .encryptedUsingKeyChain(_, excludedFromBackup):
            return excludedFromBackup
        case .encryptedUsingSecureEnclave:
            return true
        }
    }
    
    
    func keys(from keyStorage: KeyStorage) throws -> SecKeyPair? {
        let secureStorageScope: SecureStorageScope
        switch self {
        case .unencrypted:
            return nil
        case let .encrypted(keys, _):
            return keys
        case let .encryptedUsingSecureEnclave(userPresence):
            secureStorageScope = .secureEnclave(userPresence: userPresence)
        case let .encryptedUsingKeyChain(userPresence, _):
            secureStorageScope = .keychain(userPresence: userPresence)
        }
        
        let tag = "LocalStorage.\(secureStorageScope.id)"
        return try (try? keyStorage.retrieveKeyPair(forTag: tag))
            ?? keyStorage.create(tag)
    }
}

extension LocalStorageSetting {
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key: private key for encryption and a public key for decryption.
    @available(*, deprecated, renamed: "encrypted(keys:excludedFromBackup:)")
    public static func encrypted(privateKey: SecKey, publicKey: SecKey, excludedFromBackup: Bool = true) -> LocalStorageSetting {
        .encrypted(keys: (privateKey, publicKey), excludedFromBackup: excludedFromBackup)
    }
}
