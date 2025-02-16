//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import Spezi
import SpeziKeychainStorage


/// Configure how data is encrypyed, stored, and retrieved.
public enum LocalStorageSetting: Hashable, Sendable {
    /// Unencrypted
    case unencrypted(excludeFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key: private key for encryption and a public key for decryption.
    case encrypted(privateKey: SecKey, publicKey: SecKey, excludeFromBackup: Bool = true)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Secure Enclave.
    case encryptedUsingSecureEnclave(userPresence: Bool = false)
    /// Encrypted using a `eciesEncryptionCofactorX963SHA256AESGCM` key stored in the Keychain.
    case encryptedUsingKeychain(userPresence: Bool = false, excludeFromBackup: Bool = true)
    
    
    var isExcludedFromBackup: Bool {
        switch self {
        case let .unencrypted(excludeFromBackup),
             let .encrypted(_, _, excludeFromBackup),
             let .encryptedUsingKeychain(_, excludeFromBackup):
            return excludeFromBackup
        case .encryptedUsingSecureEnclave:
            return true
        }
    }
    
    
    func keys(from keychain: KeychainStorage) throws -> (privateKey: SecKey, publicKey: SecKey)? {
        let storageOption: KeychainItemStorageOption
        switch self {
        case .unencrypted:
            return nil
        case let .encrypted(privateKey, publicKey, _):
            return (privateKey, publicKey)
        case let .encryptedUsingSecureEnclave(userPresence):
            storageOption = .secureEnclave(requireUserPresence: userPresence)
        case let .encryptedUsingKeychain(userPresence, _):
            storageOption = .keychain(requireUserPresence: userPresence, accessGroup: nil)
        }
        
        let keyTag = CryptographicKeyTag(
            "LocalStorage.\(storageOption.id)",
            storage: .secureEnclave(requireUserPresence: false)
        )
        
        if let privateKey = try? keychain.retrievePrivateKey(for: keyTag),
           let publicKey = try? keychain.retrievePublicKey(for: keyTag) {
            return (privateKey, publicKey)
        }
        
        let privateKey = try keychain.createKey(for: keyTag)
        guard let publicKey = try keychain.retrievePublicKey(for: keyTag) else {
            throw LocalStorageError.encryptionNotPossible
        }
        
        return (privateKey, publicKey)
    }
}
