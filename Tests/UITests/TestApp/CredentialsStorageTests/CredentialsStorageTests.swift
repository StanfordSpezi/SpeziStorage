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
        let serverCredentials1 = Credentials(username: "@Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(credentials: serverCredentials1, server: "apple.com")
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(credentials: serverCredentials2)
        
        try credentialsStorage.createKey("DeleteKeyTest", storageScope: .keychain)
        
        try credentialsStorage.deleteAllCredentials()
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(forServer: "apple.com")).count, 0)
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials()).count, 0)
        try XCTAssertNil(credentialsStorage.retrievePrivateKey(forTag: "DeleteKeyTest"))
        try XCTAssertNil(credentialsStorage.retrievePublicKey(forTag: "DeleteKeyTest"))
    }
    
    
    func testCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(credentials: serverCredentials)
        try credentialsStorage.store(credentials: serverCredentials, storageScope: .keychainSynchronizable)
        try credentialsStorage.store(credentials: serverCredentials, storageScope: .keychainSynchronizable) // Overwrite existing credentials.
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials("@PSchmiedmayer"))
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        try XCTAssertEqual(serverCredentials.id, retrievedCredentials.id)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try credentialsStorage.updateCredentials("@PSchmiedmayer", newCredentials: serverCredentials)
        
        let retrievedUpdatedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials("@Spezi"))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try credentialsStorage.deleteCredentials("@Spezi")
        try XCTAssertNil(try credentialsStorage.retrieveCredentials("@Spezi"))
    }
    
    
    func testInternetCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(credentials: serverCredentials, server: "twitter.com")
        try credentialsStorage.store(credentials: serverCredentials, server: "twitter.com") // Overwrite existing credentials.
        try credentialsStorage.store(
            credentials: serverCredentials,
            server: "twitter.com",
            storageScope: .keychainSynchronizable
        )
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials("@PSchmiedmayer", server: "twitter.com"))
        try XCTAssertEqual(serverCredentials, retrievedCredentials)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try credentialsStorage.updateCredentials("@PSchmiedmayer", server: "twitter.com", newCredentials: serverCredentials, newServer: "stanford.edu")
        
        let retrievedUpdatedCredentials = try XCTUnwrap(credentialsStorage.retrieveCredentials("@Spezi", server: "stanford.edu"))
        try XCTAssertEqual(serverCredentials, retrievedUpdatedCredentials)
        
        
        try credentialsStorage.deleteCredentials("@Spezi", server: "stanford.edu")
        try XCTAssertNil(try credentialsStorage.retrieveCredentials("@Spezi", server: "stanford.edu"))
    }
    
    
    func testMultipleInternetCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(credentials: serverCredentials1, server: "linkedin.com")
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(credentials: serverCredentials2, server: "linkedin.com")
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveAllCredentials(forServer: "linkedin.com"))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials1 }))
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials2 }))
        
        try credentialsStorage.deleteCredentials("Paul Schmiedmayer", server: "linkedin.com")
        try credentialsStorage.deleteCredentials("Stanford Spezi", server: "linkedin.com")
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials(forServer: "linkedin.com")).count, 0)
    }
    
    
    func testMultipleCredentials() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .credentials)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try credentialsStorage.store(credentials: serverCredentials1)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try credentialsStorage.store(credentials: serverCredentials2)
        
        let retrievedCredentials = try XCTUnwrap(credentialsStorage.retrieveAllCredentials())
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials1 }))
        try XCTAssert(retrievedCredentials.contains(where: { $0 == serverCredentials2 }))
        
        try credentialsStorage.deleteCredentials("Paul Schmiedmayer")
        try credentialsStorage.deleteCredentials("Stanford Spezi")
        
        try XCTAssertEqual(try XCTUnwrap(credentialsStorage.retrieveAllCredentials()).count, 0)
    }
    
    
    func testKeys() throws {
        try credentialsStorage.deleteAllCredentials(itemTypes: .keys)
        try XCTAssertNil(try credentialsStorage.retrievePublicKey(forTag: "MyKey"))
        
        try credentialsStorage.createKey("MyKey", storageScope: .keychain)
        try credentialsStorage.createKey("MyKey", storageScope: .keychainSynchronizable)
        if SecureEnclave.isAvailable {
            try credentialsStorage.createKey("MyKey", storageScope: .secureEnclave)
        }
        
        let privateKey = try XCTUnwrap(credentialsStorage.retrievePrivateKey(forTag: "MyKey"))
        let publicKey = try XCTUnwrap(credentialsStorage.retrievePublicKey(forTag: "MyKey"))
        
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
        
        try credentialsStorage.deleteKeys(forTag: "MyKey")
        try XCTAssertNil(try credentialsStorage.retrievePrivateKey(forTag: "MyKey"))
        try XCTAssertNil(try credentialsStorage.retrievePublicKey(forTag: "MyKey"))
    }
}
