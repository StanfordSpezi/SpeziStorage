//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziLocalStorage
import XCTest
import XCTSpezi


private struct Letter: Codable, Equatable {
    let greeting: String
}


extension LocalStorageKeys { // swiftlint:disable:this file_types_order
    fileprivate static let letter = LocalStorageKey<Letter>("letter", setting: .unencrypted())
}


final class LocalStorageTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Before each test, we want to fully reset the LocalStorage
        try await MainActor.run {
            let localStorage = LocalStorage()
            withDependencyResolution {
                localStorage
            }
            try localStorage.deleteAll()
        }
    }
    
    
    @MainActor
    func testLocalStorage() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        try localStorage.store(letter, for: .letter)
        let storedLetter = try localStorage.load(.letter)
        
        XCTAssertEqual(letter, storedLetter)
    }
    
    
    @MainActor
    func testLocalStorageDeletion() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        
        // 1: test "normal" deletion
        try localStorage.store(letter, for: .letter)
        XCTAssertEqual(letter, try localStorage.load(.letter))
        try localStorage.delete(.letter)
        XCTAssertNil(try localStorage.load(.letter))
        XCTAssertNoThrow(try localStorage.delete(.letter))
        
        // 2: test deletion by storing nil
        try localStorage.store(letter, for: .letter)
        XCTAssertEqual(letter, try localStorage.load(.letter))
        try localStorage.store(nil, for: .letter)
        XCTAssertNil(try localStorage.load(.letter))
        XCTAssertNoThrow(try localStorage.delete(.letter))
    }
    
    
    @MainActor
    func testExcludeFromBackupFlag() throws {
        func assertItemAtUrlIsExcludedFromBackupEquals(
            _ url: URL,
            shouldBeExcluded: Bool,
            file: StaticString = #filePath,
            line: UInt = #line
        ) throws {
            let isExcluded = try XCTUnwrap(url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup)
            XCTAssertEqual(isExcluded, shouldBeExcluded, file: file, line: line)
        }
        
        let keyYesBackup = LocalStorageKey<Letter>("letter1", setting: .unencrypted(excludeFromBackup: false))
        let keyNoBackup = LocalStorageKey<Letter>("letter2", setting: .unencrypted(excludeFromBackup: true))
        
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let letter = Letter(greeting: "Hello Lukas 😳😳😳")
        
        try localStorage.store(letter, for: keyNoBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(
            localStorage.fileURL(for: keyNoBackup),
            shouldBeExcluded: keyNoBackup.setting.isExcludedFromBackup
        )
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(
            localStorage.fileURL(for: keyYesBackup),
            shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup
        )
        
        try localStorage.deleteAll()
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(
            localStorage.fileURL(for: keyYesBackup),
            shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup
        )
        
        try localStorage.store(letter, for: keyNoBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(
            localStorage.fileURL(for: keyNoBackup),
            shouldBeExcluded: keyNoBackup.setting.isExcludedFromBackup
        )
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(
            localStorage.fileURL(for: keyYesBackup),
            shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup
        )
    }
    
    
    @MainActor
    func testDeleteAll() throws {
        let fileManager = FileManager.default
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let localStorageDir = localStorage.localStorageDirectory
        do {
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: localStorageDir.path, isDirectory: &isDirectory)
            XCTAssertTrue(exists)
            XCTAssertTrue(isDirectory.boolValue)
        }
        
        XCTAssertTrue(try fileManager.contentsOfDirectory(atPath: localStorageDir.path).isEmpty)
        
        try localStorage.store("Servus", for: .init("hmmmm", setting: .unencrypted()))
        XCTAssertFalse(try fileManager.contentsOfDirectory(atPath: localStorageDir.path).isEmpty)
        try localStorage.deleteAll()
        XCTAssertTrue(try fileManager.contentsOfDirectory(atPath: localStorageDir.path).isEmpty)
    }
    
    
    @MainActor
    func testModify() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let key = LocalStorageKey<String>("abcabc", setting: .unencrypted())
        XCTAssertFalse(localStorage.hasEntry(for: key))
        try localStorage.modify(key) { value in
            XCTAssertNil(value)
            value = "heyyy"
        }
        XCTAssertTrue(localStorage.hasEntry(for: key))
        XCTAssertEqual(try localStorage.load(key), "heyyy")
        try localStorage.modify(key) { value in
            XCTAssertNotNil(value)
            XCTAssertEqual(value, "heyyy")
            value = nil
        }
        XCTAssertFalse(localStorage.hasEntry(for: key))
    }
    
    
    @MainActor
    func testStoreData() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        // Test that raw data is not run through an extra encoding/decoding step, and instead simply encoded/decoded as-is.
        let key = LocalStorageKey<Data>("ayoooo", setting: .unencrypted())
        let data = Data([83, 112, 101, 122, 105, 32, 105, 115, 32, 99, 111, 111, 108])
        try localStorage.store(data, for: key)
        XCTAssertEqual(try Data(contentsOf: localStorage.fileURL(for: key)), data)
        XCTAssertEqual(try localStorage.load(key), data)
    }
    
    
    @MainActor
    func testNSSecureCoding() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let key = LocalStorageKey<NSString>("testTest123", setting: .unencrypted())
        let string = "hello, spezi" as NSString
        try localStorage.store(string, for: key)
        XCTAssertTrue(string.isEqual(try localStorage.load(key)))
        XCTAssertFalse(string is any Codable) // make sure we're actually using the NSSecureCoding path here...
    }
    
    
    @MainActor
    func testCodableWithConfiguration() throws {
        struct TestType: Hashable, CodableWithConfiguration {
            struct EncodingConfiguration {
                let multiplicativeFactor: Int
            }
            struct DecodingConfiguration {
                let multiplicativeFactor: Int
            }
            let value: Int
            init(value: Int) {
                self.value = value
            }
            init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
                let container = try decoder.singleValueContainer()
                value = try container.decode(Int.self) * configuration.multiplicativeFactor
            }
            func encode(to encoder: any Encoder, configuration: EncodingConfiguration) throws {
                var container = encoder.singleValueContainer()
                try container.encode(value / configuration.multiplicativeFactor)
            }
        }
        
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let key = LocalStorageKey<TestType>(
            "testtestCodableWithConfig",
            setting: .unencrypted(excludeFromBackup: true),
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )
        
        let inputValue = TestType(value: 12)
        try localStorage.store(inputValue, for: key, configuration: .init(multiplicativeFactor: 2))
        XCTAssertEqual(try String(contentsOf: localStorage.fileURL(for: key), encoding: .utf8), "6")
        XCTAssertEqual(try localStorage.load(key, configuration: .init(multiplicativeFactor: 2)), inputValue)
    }
    
    
    @MainActor
    func testCodableWithConfiguration2() throws {
        struct TestType: Hashable, Codable, CodableWithConfiguration {
            struct EncodingConfiguration {
                let multiplicativeFactor: Int
            }
            struct DecodingConfiguration {
                let multiplicativeFactor: Int
            }
            var value: Int
            init(value: Int) {
                self.value = value
            }
            init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                value = try container.decode(Int.self, forKey: .value) * configuration.multiplicativeFactor
            }
            func encode(to encoder: any Encoder, configuration: EncodingConfiguration) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(value / configuration.multiplicativeFactor, forKey: .value)
            }
        }
        
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let key = LocalStorageKey<TestType>(
            "testtestCodableWithConfig",
            setting: .unencrypted(excludeFromBackup: true),
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )
        
        let inputValue = TestType(value: 12)
        try localStorage.store(inputValue, for: key, configuration: .init(multiplicativeFactor: 2))
        XCTAssertEqual(try String(contentsOf: localStorage.fileURL(for: key), encoding: .utf8), #"{"value":6}"#)
        XCTAssertEqual(try localStorage.load(key, configuration: .init(multiplicativeFactor: 2)), inputValue)
        
        try localStorage.delete(key)
        
        try localStorage.store(inputValue, for: key)
        XCTAssertEqual(try String(contentsOf: localStorage.fileURL(for: key), encoding: .utf8), #"{"value":12}"#)
        XCTAssertEqual(try localStorage.load(key), inputValue)
        
        try localStorage.store(inputValue, for: key, configuration: .init(multiplicativeFactor: 2))
        
        try localStorage.modify(
            key,
            decodingConfiguration: .init(multiplicativeFactor: 2),
            encodingConfiguration: .init(multiplicativeFactor: 2)
        ) { value in
            value?.value += 2
        }
        
        XCTAssertEqual(try localStorage.load(key, configuration: .init(multiplicativeFactor: 2))?.value, 14)
    }
}
