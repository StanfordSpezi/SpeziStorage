//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import SpeziLocalStorage
import SpeziSecureStorage
import XCTestApp
import XCTRuntimeAssertions


final class LocalStorageTests: TestAppTestCase {
    struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    
    let localStorage: LocalStorage
    let secureStorage: SecureStorage
    
    
    init(
        localStorage: LocalStorage,
        secureStorage: SecureStorage
    ) {
        self.localStorage = localStorage
        self.secureStorage = secureStorage
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
        let privateKey = try secureStorage.retrievePrivateKey(forTag: "LocalStorageTests") ?? secureStorage.createKey("LocalStorageTests")
        guard let publicKey = try secureStorage.retrievePublicKey(forTag: "LocalStorageTests") else {
            throw XCTestFailure()
        }
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        try localStorage.store(letter, settings: .encrypted(privateKey: privateKey, publicKey: publicKey))
        let storedLetter: Letter = try localStorage.read(settings: .encrypted(privateKey: privateKey, publicKey: publicKey))
        
        try XCTAssertEqual(letter, storedLetter)
    }
    
    func testLocalStorageTestEncryptedKeychain() throws {
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")

        try localStorage.store(letter, settings: .encryptedUsingKeyChain())
        let storedLetter: Letter = try localStorage.read(settings: .encryptedUsingKeyChain())

        try XCTAssertEqual(letter, storedLetter)
    }

    func testLocalStorageTestEncryptedSecureEnclave() throws {
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        try localStorage.store(letter, settings: .encryptedUsingSecureEnclave())
        let storedLetter: Letter = try localStorage.read(settings: .encryptedUsingSecureEnclave())
        
        try XCTAssertEqual(letter, storedLetter)
    }
}
