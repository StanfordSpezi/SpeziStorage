//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import SpeziKeychainStorage
import SpeziLocalStorage
import XCTestApp
import XCTRuntimeAssertions


final class LocalStorageTests: TestAppTestCase {
    struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    
    let localStorage: LocalStorage
    let keychainStorage: KeychainStorage
    
    
    init(
        localStorage: LocalStorage,
        keychainStorage: KeychainStorage
    ) {
        self.localStorage = localStorage
        self.keychainStorage = keychainStorage
    }
    
    
    func runTests() async throws {
        try testLocalStorageTestEncryptedManualKeys()
        // Call test methods multiple times to test retrieval of keys.
        try testLocalStorageTestEncryptedKeychain()
        try testLocalStorageTestEncryptedKeychain()
        
        if SecureEnclave.isAvailable {
            try testLocalStorageTestEncryptedSecureEnclave()
            try testLocalStorageTestEncryptedSecureEnclave()
        }
    }
    
    func testLocalStorageTestEncryptedManualKeys() throws {
        let keyTag = CryptographicKeyTag("LocalStorageTests", storage: .keychain)
        let privateKey = try keychainStorage.retrievePrivateKey(for: keyTag) ?? keychainStorage.createKey(for: keyTag)
        guard let publicKey = try keychainStorage.retrievePublicKey(for: keyTag) else {
            throw XCTestFailure()
        }
        let key = LocalStorageKey<Letter>("letter1", setting: .encrypted(privateKey: privateKey, publicKey: publicKey))
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        try localStorage.store(letter, for: key)
        let storedLetter = try localStorage.load(key)
        
        try XCTAssertEqual(letter, storedLetter)
    }
    
    
    func testLocalStorageTestEncryptedKeychain() throws {
        let key = LocalStorageKey<Letter>("letter2", setting: .encryptedUsingKeychain())
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")

        try localStorage.store(letter, for: key)
        let storedLetter = try localStorage.load(key)
        
        try XCTAssertEqual(letter, storedLetter)
    }
    
    
    func testLocalStorageTestEncryptedSecureEnclave() throws {
        let key = LocalStorageKey<Letter>("letter3", setting: .encryptedUsingSecureEnclave())
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        try localStorage.store(letter, for: key)
        let storedLetter = try localStorage.load(key)
        
        try XCTAssertEqual(letter, storedLetter)
    }
}
