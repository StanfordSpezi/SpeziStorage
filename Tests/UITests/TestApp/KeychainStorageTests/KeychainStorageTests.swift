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
@_spi(Internal) import SpeziKeychainStorage
import XCTestApp
import XCTRuntimeAssertions


func XCTAssertCredentialsMainPropertiesEqual(
    _ lhs: Credentials,
    _ rhs: Credentials,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    /// indicates that both `lhs` and `rhs` are "full" credentials objects, i.e. obtained from a keychain query and fully populated
    /// (rather than manually created and containing only a username and a password.
    /// there are some properties we only can check for equality if both credentials objects were obtained from the keychain (ie, are "full" objects).
    let bothAreFullObjects: Bool
    
    switch (lhs._creationKind, rhs._creationKind) {
    case (.keychainQuery, .keychainQuery):
        bothAreFullObjects = true
    case (.manual, _), (_, .manual):
        bothAreFullObjects = false
    }
    
    try XCTAssertEqual(lhs.username, rhs.username, file: file, line: line)
    try XCTAssertEqual(lhs.password, rhs.password, file: file, line: line)
    
    if bothAreFullObjects {
        try XCTAssertEqual(lhs.kind, rhs.kind, file: file, line: line)
        try XCTAssertEqual(lhs.description, rhs.description, file: file, line: line)
        try XCTAssertEqual(lhs.label, rhs.label, file: file, line: line)
        try XCTAssertEqual(lhs.comment, rhs.comment, file: file, line: line)
        try XCTAssertEqual(lhs.synchronizable, rhs.synchronizable, file: file, line: line)
    }
}


func `throws`(_ block: () throws -> Void) -> Bool {
    do {
        try block()
        return false
    } catch {
        return true
    }
}


final class KeychainStorageTests: TestAppTestCase {
    let keychainStorage: KeychainStorage
    
    init(keychainStorage: KeychainStorage) {
        self.keychainStorage = keychainStorage
    }
    
    
    func runTests() async throws {
        #if os(macOS)
        guard ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" else {
            print("Skipping bc running this on a local mac would mess up the keychain and likely delete stuff from other applications")
            return
        }
        #endif
        try testDeleteCredentials()
        try testCredentials()
        try testInternetCredentials()
        try testMultipleInternetCredentials()
        try testMultipleCredentials()
        try testKeys0()
        try testKeys()
        try testKeys2()
    }
    
    
    func testDeleteCredentials() throws {
        let appleCredentialsTag = CredentialsTag.internetPassword(forServer: "apple.com")
        let testKeyTag = CryptographicKeyTag("DeleteKeyTest", storage: .keychain)
        
        let serverCredentials1 = Credentials(username: "@Schmiedmayer", password: "SpeziInventor")
        try keychainStorage.store(serverCredentials1, for: appleCredentialsTag)
        try XCTAssertCredentialsMainPropertiesEqual(
            serverCredentials1,
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@Schmiedmayer", for: appleCredentialsTag))
        )
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try keychainStorage.store(serverCredentials2, for: .genericPassword(forService: "speziLogin"))
        try XCTAssertCredentialsMainPropertiesEqual(
            serverCredentials2,
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "Stanford Spezi", for: .genericPassword(forService: "speziLogin")))
        )
        
        try keychainStorage.createKey(for: testKeyTag)
        
        try XCTAssertNotNil(try keychainStorage.retrievePrivateKey(for: testKeyTag))
        try XCTAssertNotNil(try keychainStorage.retrievePublicKey(for: testKeyTag))
        
        try keychainStorage.deleteAllCredentials(accessGroup: .any)
        
        try XCTAssertEqual(try XCTUnwrap(keychainStorage.retrieveAllCredentials(withUsername: nil, for: appleCredentialsTag)).count, 0)
        try XCTAssertEqual(try XCTUnwrap(keychainStorage.retrieveAllInternetCredentials()).count, 0)
        try XCTAssertEqual(
            try XCTUnwrap(keychainStorage.retrieveAllCredentials(withUsername: nil, for: .genericPassword(forService: "speziLogin"))).count,
            0
        )
        try XCTAssertEqual(try XCTUnwrap(keychainStorage.retrieveAllGenericCredentials()).count, 0)
        
        try keychainStorage.deleteAllKeys(accessGroup: .any)
        try XCTAssertNil(keychainStorage.retrievePrivateKey(for: testKeyTag))
        try XCTAssertNil(keychainStorage.retrievePublicKey(for: testKeyTag))
    }
    
    
    func testCredentials() throws {
        try keychainStorage.deleteAllCredentials(accessGroup: .any)
        
        let speziLoginTagNoSync = CredentialsTag.genericPassword(forService: "speziLogin", storage: .keychain)
        let speziLoginTagYesSync = CredentialsTag.genericPassword(forService: "speziLogin", storage: .keychainSynchronizable)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try keychainStorage.store(serverCredentials, for: speziLoginTagNoSync)
        try XCTAssertFalse(
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync)).synchronizable
        )
        do {
            let credentials = try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync))
            try XCTAssertNotNil(credentials.asGenericCredentials)
            try XCTAssertNil(credentials.asInternetCredentials)
        }
        try keychainStorage.store(serverCredentials, for: speziLoginTagYesSync)
        try XCTAssertTrue(
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync)).synchronizable
        )
        try keychainStorage.store(serverCredentials, for: speziLoginTagYesSync) // Overwrite existing credentials
        try XCTAssertTrue(
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync)).synchronizable
        )
        
        try XCTAssertCredentialsMainPropertiesEqual(
            serverCredentials,
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync))
        )
        try XCTAssertCredentialsMainPropertiesEqual(
            serverCredentials,
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync))
        )
        try XCTAssertEqual(
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync)),
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync))
        )
        try XCTAssertEqual(
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync)),
            try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync))
        )
        do {
            var credentialsSet = Set<Credentials>()
            try XCTAssertEqual(credentialsSet.count, 0)
            
            credentialsSet.insert(try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync)))
            try XCTAssertEqual(credentialsSet.count, 1)
            credentialsSet.insert(try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagNoSync)))
            try XCTAssertEqual(credentialsSet.count, 1)
            
            credentialsSet.insert(try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync)))
            try XCTAssertEqual(credentialsSet.count, 2)
            credentialsSet.insert(try XCTUnwrap(try keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync)))
            try XCTAssertEqual(credentialsSet.count, 2)
        }
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try keychainStorage.updateCredentials(withUsername: "@PSchmiedmayer", for: speziLoginTagYesSync, with: serverCredentials)
        
        let retrievedUpdatedCredentials = try XCTUnwrap(keychainStorage.retrieveCredentials(withUsername: "@Spezi", for: speziLoginTagYesSync))
        try XCTAssertCredentialsMainPropertiesEqual(serverCredentials, retrievedUpdatedCredentials)
        
        try keychainStorage.deleteCredentials(withUsername: "@Spezi", for: speziLoginTagYesSync)
        try XCTAssertNil(try keychainStorage.retrieveCredentials(withUsername: "@Spezi", for: speziLoginTagYesSync))
    }
    
    
    func testInternetCredentials() throws {
        let twitterCredentialsKey = CredentialsTag.internetPassword(forServer: "twitter.com", storage: .keychain)
        try keychainStorage.deleteAllCredentials(accessGroup: .any)
        
        var serverCredentials = Credentials(username: "@PSchmiedmayer", password: "SpeziInventor")
        try keychainStorage.store(serverCredentials, for: twitterCredentialsKey)
        try keychainStorage.store(serverCredentials, for: twitterCredentialsKey) // Overwrite existing credentials.
        try keychainStorage.store(serverCredentials, for: .internetPassword(forServer: "twitter.com", storage: .keychainSynchronizable))
        
        let retrievedCredentials = try XCTUnwrap(
            keychainStorage.retrieveCredentials(withUsername: "@PSchmiedmayer", for: twitterCredentialsKey)
        )
        try XCTAssertCredentialsMainPropertiesEqual(serverCredentials, retrievedCredentials)
        
        
        serverCredentials = Credentials(username: "@Spezi", password: "Paul")
        try keychainStorage.updateCredentials(
            withUsername: "@PSchmiedmayer",
            for: twitterCredentialsKey,
            with: serverCredentials
        )
        
        let retrievedUpdatedCredentials = try XCTUnwrap(keychainStorage.retrieveCredentials(withUsername: "@Spezi", for: twitterCredentialsKey))
        try XCTAssertCredentialsMainPropertiesEqual(serverCredentials, retrievedUpdatedCredentials)
        
        try keychainStorage.deleteCredentials(withUsername: "@Spezi", for: twitterCredentialsKey)
        try XCTAssertNil(try keychainStorage.retrieveCredentials(withUsername: "@Spezi", for: twitterCredentialsKey))
    }
    
    
    func testMultipleInternetCredentials() throws {
        let linkedInCredentialsKey = CredentialsTag.internetPassword(forServer: "linkedin.com")
        try keychainStorage.deleteAllCredentials(accessGroup: .any)
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try keychainStorage.store(serverCredentials1, for: linkedInCredentialsKey)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try keychainStorage.store(serverCredentials2, for: linkedInCredentialsKey)
        
        let retrievedCredentials = try XCTUnwrap(keychainStorage.retrieveAllCredentials(for: linkedInCredentialsKey))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssertNotNil(retrievedCredentials[0].asInternetCredentials)
        try XCTAssertNotNil(retrievedCredentials[1].asInternetCredentials)
        try XCTAssertNil(retrievedCredentials[0].asGenericCredentials)
        try XCTAssertNil(retrievedCredentials[1].asGenericCredentials)
        try XCTAssert(retrievedCredentials.contains { cred in !`throws` { try XCTAssertCredentialsMainPropertiesEqual(cred, serverCredentials1) } })
        try XCTAssert(retrievedCredentials.contains { cred in !`throws` { try XCTAssertCredentialsMainPropertiesEqual(cred, serverCredentials2) } })
        
        try keychainStorage.deleteCredentials(withUsername: "Paul Schmiedmayer", for: linkedInCredentialsKey)
        try keychainStorage.deleteCredentials(withUsername: "Stanford Spezi", for: linkedInCredentialsKey)
        
        try XCTAssertEqual(try XCTUnwrap(keychainStorage.retrieveAllCredentials(for: linkedInCredentialsKey)).count, 0)
    }
    
    
    func testMultipleCredentials() throws {
        try keychainStorage.deleteAllCredentials(accessGroup: .any)
        
        let stanfordCredentialsTag = CredentialsTag.internetPassword(forServer: "stanford.edu")
        
        let serverCredentials1 = Credentials(username: "Paul Schmiedmayer", password: "SpeziInventor")
        try keychainStorage.store(serverCredentials1, for: stanfordCredentialsTag)
        
        let serverCredentials2 = Credentials(username: "Stanford Spezi", password: "Paul")
        try keychainStorage.store(serverCredentials2, for: stanfordCredentialsTag)
        
        let retrievedCredentials = try XCTUnwrap(keychainStorage.retrieveAllCredentials(for: stanfordCredentialsTag))
        try XCTAssertEqual(retrievedCredentials.count, 2)
        try XCTAssert(retrievedCredentials.contains { cred in !`throws` { try XCTAssertCredentialsMainPropertiesEqual(cred, serverCredentials1) } })
        try XCTAssert(retrievedCredentials.contains { cred in !`throws` { try XCTAssertCredentialsMainPropertiesEqual(cred, serverCredentials2) } })
        
        try keychainStorage.deleteCredentials(withUsername: "Paul Schmiedmayer", for: stanfordCredentialsTag)
        try keychainStorage.deleteCredentials(withUsername: "Stanford Spezi", for: stanfordCredentialsTag)
        
        try XCTAssertEqual(try XCTUnwrap(keychainStorage.retrieveAllCredentials(for: stanfordCredentialsTag)).count, 0)
    }
    
    
    func testKeys0() throws {
        let tag = CryptographicKeyTag("edu.stanford.spezi.testKey", storage: .keychain, label: "TestKey Label")
        
        let key = try keychainStorage.createKey(for: tag)
        defer {
            try! keychainStorage.deleteKey(key) // swiftlint:disable:this force_try
        }
        try XCTAssertEqual(key.label, tag.label)
        try XCTAssertEqual(key.applicationTag, tag.tagValue)
        try XCTAssertEqual(key.sizeInBits, tag.size)
    }
    
    
    func testKeys() throws {
        let keyTag1 = CryptographicKeyTag("MyKey1", storage: .keychain, label: "MyKey1")
        let keyTag2 = CryptographicKeyTag("MyKey2", storage: .keychainSynchronizable, label: "MyKey2")
        let keyTag3 = CryptographicKeyTag("MyKey3", storage: .secureEnclave, label: "MyKey3")
        
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag1))
        try XCTAssertNil(try keychainStorage.retrievePublicKey(for: keyTag1))
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag2))
        try XCTAssertNil(try keychainStorage.retrievePublicKey(for: keyTag2))
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag3))
        try XCTAssertNil(try keychainStorage.retrievePublicKey(for: keyTag3))
        
        try keychainStorage.createKey(for: keyTag1)
        try keychainStorage.createKey(for: keyTag2)
        
        try XCTAssertNotNil(try keychainStorage.retrievePrivateKey(for: keyTag1))
        try XCTAssertNotNil(try keychainStorage.retrievePublicKey(for: keyTag1))
        try XCTAssertNotNil(try keychainStorage.retrievePrivateKey(for: keyTag2))
        try XCTAssertNotNil(try keychainStorage.retrievePublicKey(for: keyTag2))
        
        if SecureEnclave.isAvailable {
            try keychainStorage.createKey(for: keyTag3)
            let privateKey = try XCTUnwrap(keychainStorage.retrievePrivateKey(for: keyTag3))
            let publicKey = try XCTUnwrap(keychainStorage.retrievePublicKey(for: keyTag3))
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
            try keychainStorage.deleteKey(for: keyTag3)
        }
        
        try keychainStorage.deleteKey(for: keyTag1)
        try keychainStorage.deleteKey(for: keyTag2)
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag1))
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag2))
        try XCTAssertNil(try keychainStorage.retrievePrivateKey(for: keyTag3))
    }
    
    
    func testKeys2() throws {
        var storageOptionsToTest: [KeychainItemStorageOption] = [
            .secureEnclave(requireUserPresence: false),
            .secureEnclave(requireUserPresence: true),
            .keychain(requireUserPresence: false, accessGroup: nil),
            .keychain(requireUserPresence: false, accessGroup: "637867499T.edu.stanford.spezi.storage.testapp"),
            .keychain(requireUserPresence: true, accessGroup: nil),
            .keychain(requireUserPresence: true, accessGroup: "637867499T.edu.stanford.spezi.storage.testapp"),
            .keychainSynchronizable(accessGroup: nil),
            .keychainSynchronizable(accessGroup: "637867499T.edu.stanford.spezi.storage.testapp")
        ]
        #if targetEnvironment(simulator)
        // secure enclave isn't really supported on the simulator
        storageOptionsToTest.removeFirst(2)
        #endif
        
        for (idx, storageOption) in storageOptionsToTest.enumerated() {
            let tag = CryptographicKeyTag("edu.stanford.spezi.testKey_\(idx)", storage: storageOption)
            let key = try keychainStorage.createKey(for: tag)
            do {
                try XCTAssertEqual(key, try keychainStorage.retrievePrivateKey(for: tag))
                try keychainStorage.deleteKey(key)
            } catch {
                try keychainStorage.deleteKey(key)
                throw error
            }
        }
    }
}
