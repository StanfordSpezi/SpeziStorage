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


final class LocalStorageTests: XCTestCase {
    private struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    
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
        try localStorage.store(letter, settings: .unencrypted())
        let storedLetter: Letter = try localStorage.read(settings: .unencrypted())
        
        XCTAssertEqual(letter, storedLetter)
        
        try localStorage.delete(Letter.self)
        try localStorage.delete(storageKey: "Letter")
    }
    
    
    @MainActor
    func testLocalStorageDeletion() throws {
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        try localStorage.store(letter, settings: .unencrypted())
        let storedLetter: Letter = try localStorage.read(settings: .unencrypted())
        
        XCTAssertEqual(letter, storedLetter)
        
        try localStorage.delete(Letter.self)
        XCTAssertThrowsError(try localStorage.read(Letter.self, settings: .unencrypted()))
        XCTAssertNoThrow(try localStorage.delete(Letter.self))
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
        
        let localStorage = LocalStorage()
        withDependencyResolution {
            localStorage
        }
        
        let letter = Letter(greeting: "Hello Lukas 😳😳😳")
        
        try localStorage.store(letter, storageKey: "letter", settings: .unencrypted(excludedFromBackup: true))
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(from: "letter", type: Letter.self), shouldBeExcluded: true)
        
        try localStorage.store(letter, storageKey: "letter", settings: .unencrypted(excludedFromBackup: false))
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(from: "letter", type: Letter.self), shouldBeExcluded: false)
        
        try localStorage.delete(storageKey: "letter")
        
        try localStorage.store(letter, storageKey: "letter", settings: .unencrypted(excludedFromBackup: false))
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(from: "letter", type: Letter.self), shouldBeExcluded: false)
        
        try localStorage.store(letter, storageKey: "letter", settings: .unencrypted(excludedFromBackup: true))
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(from: "letter", type: Letter.self), shouldBeExcluded: true)
        
        try localStorage.store(letter, storageKey: "letter", settings: .unencrypted(excludedFromBackup: false))
        try assertItemAtUrlIsExcludedFromBackupEquals(localStorage.fileURL(from: "letter", type: Letter.self), shouldBeExcluded: false)
    }
}
