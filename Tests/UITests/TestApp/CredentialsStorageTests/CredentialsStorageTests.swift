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
import SpeziCredentialsStorage
import XCTestApp
import XCTRuntimeAssertions


final class CredentialsStorageTests: TestAppTestCase {
    let credentialsStorage: CredentialsStorage
    
    
    init(credentialsStorage: CredentialsStorage) {
        self.credentialsStorage = credentialsStorage
    }
    
    
    func runTests() async throws {
        try testDeleteAllCredentials()
        try testCredentials()
        try testInternetCredentials()
        try testMultipleInternetCredentials()
        try testMultipleCredentials()
        try testKeys()
    }
    
    
    func testDeleteAllCredentials() throws {
        let appleCredentialsKey = CredentialsStorageKey.internetPassword(forServer: "apple.com")
        let testKeyTag = KeyTag("DeleteKeyTest")
        
        let serverCredentials1 = Credentials(username: "@Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(serverCredentials1, for: appleCredentialsKey)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(serverCredentials2, for: .genericPassword())
        
        try credentialsStorage.createKey(for: testKeyTag, storageScope: .keychain())
        
        try credentialsStorage.deleteAllCredentials()
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: appleCredentialsKey)).count, 0)
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: .genericPassword())).count, 0)
        try XCTAssertNil(credentialsStorage.retrievePrivateKey(for: testKeyTag))
        try XCTAssertNil(credentialsStorage.retrievePublicKey(for: testKeyTag))
    }
    
    
    func testCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(serverCredentials, for: .genericPassword())
        try credentialsStorage.store(serverCredentials, for: .genericPassword(withScope: .keychainSynchronizable()))
        try credentialsStorage.store(serverCredentials, for: .genericPassword(withScope: .keychainSynchronizable())) // Overwrite existing credentials
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", forKey: .genericPassword()))
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        try XCTAssertEqual(serverCredentials.id, retrievedCredentials.id)
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try credentialsStorage.updateCredentials(forUsername: "@PSchmiedmayer", key: .genericPassword(), with: serverCredentials)
        
        let retrievedUpdatedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials(withUsername: "@Spezi", forKey: .genericPassword()))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try credentialsStorage.deleteCredentials(withUsername: "@Spezi", for: .genericPassword())
        try XCTAssertNil(try credentialsStorage.retrieveCredentials(withUsername: "@Spezi", forKey: .genericPassword()))
    }
    
    
    func testInternetCredentials() throws {
        let twitterCredentialsKey = CredentialsStorageKey.internetPassword(forServer: "twitter.com", withScope: .keychain())
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(serverCredentials, for: twitterCredentialsKey)
        try credentialsStorage.store(serverCredentials, for: twitterCredentialsKey) // Overwrite existing credentials.
        try credentialsStorage.store(serverCredentials, for: .internetPassword(forServer: "twitter.com", withScope: .keychainSynchronizable()))
        
        let retrievedCredentials = try XCTUnwrap(
            credentialsStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", forKey: twitterCredentialsKey)
        )
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try credentialsStorage.updateCredentials(
            forUsername: "@PSchmiedmayer",
            key: twitterCredentialsKey,
            with: serverCredentials
        )
        
        let retrievedUpdatedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials(withUsername: "@Spezi", forKey: twitterCredentialsKey))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try credentialsStorage.deleteCredentials(withUsername: "@Spezi", for: twitterCredentialsKey)
        try XCTAssertNil(try credentialsStorage.retrieveCredentials(withUsername: "@Spezi", forKey: twitterCredentialsKey))
    }
    
    
    func testMultipleInternetCredentials() throws {
        let linkedInCredentialsKey = CredentialsStorageKey.internetPassword(forServer: "linkedin.com")
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(serverCredentials1, for: linkedInCredentialsKey)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(serverCredentials2, for: linkedInCredentialsKey)
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: linkedInCredentialsKey))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(serverCredentials1))
        try XCTAssert(retrievedCredentials.contains(serverCredentials2))
        
        try credentialsStorage.deleteCredentials(withUsername: "Paul Schmiedmayer", for: linkedInCredentialsKey)
        try credentialsStorage.deleteCredentials(withUsername: "Stanford Spezi", for: linkedInCredentialsKey)
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: linkedInCredentialsKey)).count, 0)
    }
    
    
    func testMultipleCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(serverCredentials1, for: .genericPassword())
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(serverCredentials2, for: .genericPassword())
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: .genericPassword()))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(serverCredentials1))
        try XCTAssert(retrievedCredentials.contains(serverCredentials2))
        
        try credentialsStorage.deleteCredentials(withUsername: "Paul Schmiedmayer", for: .genericPassword())
        try credentialsStorage.deleteCredentials(withUsername: "Stanford Spezi", for: .genericPassword())
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(for: .genericPassword())).count, 0)
    }
    
    
    func testKeys() throws {
        let keyTag = KeyTag("MyKey")
        try credentialsStorage.deleteAllCredentials(itemTypes: .keys)
        
        try XCTAssertNil(try credentialsStorage.retrievePublicKey(for: keyTag))
        
        try credentialsStorage.createKey(for: keyTag, storageScope: .keychain())
        try credentialsStorage.createKey(for: keyTag, storageScope: .keychainSynchronizable())
        if SecureEnclave.isAvailable {
            try credentialsStorage.createKey(for: keyTag, storageScope: .secureEnclave())
        }
        
        let privateKey = try XCTUnwrap(credentialsStorage.retrievePrivateKey(for: keyTag))
        let publicKey = try XCTUnwrap(credentialsStorage.retrievePublicKey(for: keyTag))
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw XCTestFailure()
        }
        
        let plainText = Data("Spezi & Paul Schmiedmayer".utf8)
        
        var encryptError: Unmanaged<CFError>?
        guard let cipherText = SecKeyCreateEncryptedData(publicKey, algorithm, plainText as CFData, &encryptError) as Data? else {
            throw XCTestFailure()
        }
        
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            throw XCTestFailure()
        }
        
        var decryptError: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(privateKey, algorithm, cipherText as CFData, &decryptError) as Data? else {
            throw XCTestFailure()
        }
        
        try XCTAssertEqual(plainText, clearText)
        
        try credentialsStorage.deleteKeys(for: keyTag)
        try XCTAssertNil(try credentialsStorage.retrievePrivateKey(for: keyTag))
        try XCTAssertNil(try credentialsStorage.retrievePublicKey(for: keyTag))
    }
}
