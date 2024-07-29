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
    struct Letter: Codable, Equatable {
        let greeting: String
    }

    @MainActor
    func testLocalStorage() async throws {
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
}
