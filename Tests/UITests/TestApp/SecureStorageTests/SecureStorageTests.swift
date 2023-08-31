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
import SpeziSecureStorage
import XCTestApp
import XCTRuntimeAssertions


final class SecureStorageTests: TestAppTestCase {
    let secureStorage: SecureStorage
    
    
    init(secureStorage: SecureStorage) {
        self.secureStorage = secureStorage
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
        let serverCredentials1 = Credentials(username: "@Schmiedmayer", password: "SpeziInventor")
        try secureStorage.store(credentials: serverCredentials1, server: "apple.com")
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try secureStorage.store(credentials: serverCredentials2)
        
        try secureStorage.createKey("DeleteKeyTest", storageScope: .keychain)
        
        try secureStorage.deleteAllCredentials()
        
        try XCTAssertEqual(try XCTUnwrap(secureStorage.retrieveAllCredentials(forServer: "apple.com")).count, 0)
        try XCTAssertEqual(try XCTUnwrap(secureStorage.retrieveAllCredentials()).count, 0)
        try XCTAssertNil(secureStorage.retrievePrivateKey(forTag: "DeleteKeyTest"))
        try XCTAssertNil(secureStorage.retrievePublicKey(forTag: "DeleteKeyTest"))
    }
    
    func testCredentials() throws {
        try secureStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try secureStorage.store(credentials: serverCredentials)
        try secureStorage.store(credentials: serverCredentials, storageScope: .keychainSynchronizable)
        try secureStorage.store(credentials: serverCredentials, storageScope: .keychainSynchronizable) // Overwrite existing credentials.
        
        let retrievedCredentials = try XCTUnwrap(secureStorage.retrieveCredentials("@PSchmiedmayer"))
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        try XCTAssertEqual(serverCredentials.id, retrievedCredentials.id)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try secureStorage.updateCredentials("@PSchmiedmayer", newCredentials: serverCredentials)
        
        let retrievedUpdatedCredentials = try XCTUnwrap(secureStorage.retrieveCredentials("@Spezi"))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try secureStorage.deleteCredentials("@Spezi")
        try XCTAssertNil(try secureStorage.retrieveCredentials("@Spezi"))
    }
    
    func testInternetCredentials() throws {
        try secureStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try secureStorage.store(credentials: serverCredentials, server: "twitter.com")
        try secureStorage.store(credentials: serverCredentials, server: "twitter.com") // Overwrite existing credentials.
        try secureStorage.store(
            credentials: serverCredentials,
            server: "twitter.com",
            storageScope: .keychainSynchronizable
        )
        
        let retrievedCredentials = try XCTUnwrap(secureStorage.retrieveCredentials("@PSchmiedmayer", server: "twitter.com"))
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try secureStorage.updateCredentials("@PSchmiedmayer", server: "twitter.com", newCredentials: serverCredentials, newServer: "stanford.edu")
        
        let retrievedUpdatedCredentials = try XCTUnwrap(secureStorage.retrieveCredentials("@Spezi", server: "stanford.edu"))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try secureStorage.deleteCredentials("@Spezi", server: "stanford.edu")
        try XCTAssertNil(try secureStorage.retrieveCredentials("@Spezi", server: "stanford.edu"))
    }
    
    func testMultipleInternetCredentials() throws {
        try secureStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try secureStorage.store(credentials: serverCredentials1, server: "linkedin.com")
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try secureStorage.store(credentials: serverCredentials2, server: "linkedin.com")
        
        let retrievedCredentials = try XCTUnwrap(secureStorage.retrieveAllCredentials(forServer: "linkedin.com"))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials1 }))
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials2 }))
        
        try secureStorage.deleteCredentials("Paul Schmiedmayer", server: "linkedin.com")
        try secureStorage.deleteCredentials("Stanford Spezi", server: "linkedin.com")
        
        try XCTAssertEqual(try XCTUnwrap(secureStorage.retrieveAllCredentials(forServer: "linkedin.com")).count, 0)
    }
    
    func testMultipleCredentials() throws {
        try secureStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try secureStorage.store(credentials: serverCredentials1)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try secureStorage.store(credentials: serverCredentials2)
        
        let retrievedCredentials = try XCTUnwrap(secureStorage.retrieveAllCredentials())
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials1 }))
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials2 }))
        
        try secureStorage.deleteCredentials("Paul Schmiedmayer")
        try secureStorage.deleteCredentials("Stanford Spezi")
        
        try XCTAssertEqual(try XCTUnwrap(secureStorage.retrieveAllCredentials()).count, 0)
    }
    
    func testKeys() throws {
        try secureStorage.deleteAllCredentials(itemTypes: .keys)
        try XCTAssertNil(try secureStorage.retrievePublicKey(forTag: "MyKey"))
        
        try secureStorage.createKey("MyKey", storageScope: .keychain)
        try secureStorage.createKey("MyKey", storageScope: .keychainSynchronizable)
        if SecureEnclave.isAvailable {
            try secureStorage.createKey("MyKey", storageScope: .secureEnclave)
        }
        
        let privateKey = try XCTUnwrap(secureStorage.retrievePrivateKey(forTag: "MyKey"))
        let publicKey = try XCTUnwrap(secureStorage.retrievePublicKey(forTag: "MyKey"))
        
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
        
        try secureStorage.deleteKeys(forTag: "MyKey")
        try XCTAssertNil(try secureStorage.retrievePrivateKey(forTag: "MyKey"))
        try XCTAssertNil(try secureStorage.retrievePublicKey(forTag: "MyKey"))
    }
}
