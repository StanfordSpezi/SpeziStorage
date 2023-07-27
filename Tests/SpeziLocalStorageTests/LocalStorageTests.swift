//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import Spezi
@testable import SpeziLocalStorage
import XCTest


final class LocalStorageTests: XCTestCase {
    struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    class LocalStorageTestsAppDelegate: SpeziAppDelegate {
        override var configuration: Configuration {
            Configuration() {
                LocalStorage()
            }
        }
    }
    
    
    func testLocalStorage() async throws {
        let spezi = await LocalStorageTestsAppDelegate().spezi
        let localStorage = try XCTUnwrap(spezi.storage[LocalStorage.self])
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        try localStorage.store(letter, settings: .unencrypted())
        let storedLetter: Letter = try localStorage.read(settings: .unencrypted())
        
        XCTAssertEqual(letter, storedLetter)
        
        try localStorage.delete(Letter.self)
        try localStorage.delete(storageKey: "Letter")
    }
}
