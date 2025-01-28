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


private extension LocalStorageKeys {
    static let letter = LocalStorageKey<Letter>("letter", setting: .unencrypted())
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
        try localStorage.store(letter, for: .letter)
        let storedLetter = try localStorage.load(.letter)
        
        XCTAssertEqual(letter, storedLetter)
        
        try localStorage.delete(.letter)
        XCTAssertThrowsError(try localStorage.load(.letter))
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
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(for: keyNoBackup), shouldBeExcluded: keyNoBackup.setting.isExcludedFromBackup)
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(for: keyYesBackup), shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup)
        
        try localStorage.deleteAll()
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(for: keyYesBackup), shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup)
        
        try localStorage.store(letter, for: keyNoBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(for: keyNoBackup), shouldBeExcluded: keyNoBackup.setting.isExcludedFromBackup)
        
        try localStorage.store(letter, for: keyYesBackup)
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(for: keyYesBackup), shouldBeExcluded: keyYesBackup.setting.isExcludedFromBackup)
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
        
        try localStorage.store("Servus", for: .init("hmmmm"))
        XCTAssertFalse(try fileManager.contentsOfDirectory(atPath: localStorageDir.path).isEmpty)
        try localStorage.deleteAll()
        XCTAssertTrue(try fileManager.contentsOfDirectory(atPath: localStorageDir.path).isEmpty)
    }
}
