//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import SpeziCredentialsStorage
import SpeziLocalStorage
import XCTestApp
import XCTRuntimeAssertions


final class LocalStorageTests: TestAppTestCase {
    struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    
    let localStorage: LocalStorage
    let credentialsStorage: CredentialsStorage
    
    
    init(
        localStorage: LocalStorage,
        credentialsStorage: CredentialsStorage
    ) {
        self.localStorage = localStorage
        self.credentialsStorage = credentialsStorage
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
        let keyTag = KeyTag("LocalStorageTests")
        let privateKey = try credentialsStorage.retrievePrivateKey(for: keyTag) ?? credentialsStorage.createKey(for: keyTag)
        guard let publicKey = try credentialsStorage.retrievePublicKey(for: keyTag) else {
            throw XCTestFailure()
        }
        let key = LocalStorageKey<Letter>("letter1", setting: .encrypted(privateKey: privateKey, publicKey: publicKey))
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        try localStorage.store(letter, for: key)
        let storedLetter = try localStorage.load(key)
        
        try XCTAssertEqual(letter, storedLetter)
    }
    
    
    func testLocalStorageTestEncryptedKeychain() throws {
        let key = LocalStorageKey<Letter>("letter2", setting: .encryptedUsingKeyChain())
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
