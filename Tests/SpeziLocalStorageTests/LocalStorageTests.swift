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
    private actor LocalStorageTestStandard: Standard {
        typealias BaseType = StandardType
        typealias RemovalContext = StandardType
        
        
        struct StandardType: Sendable, Identifiable {
            var id: UUID
        }
        
        
        func registerDataSource(_ asyncSequence: some TypedAsyncSequence<DataChange<BaseType, RemovalContext>>) { }
    }
    
    struct Letter: Codable, Equatable {
        let greeting: String
    }
    
    class LocalStorageTestsAppDelegate: SpeziAppDelegate {
        override var configuration: Configuration {
            Configuration(standard: LocalStorageTestStandard()) {
                LocalStorage()
            }
        }
    }
    
    
    func testLocalStorage() async throws {
        let spezi = await LocalStorageTestsAppDelegate().spezi
        let localStorage = try XCTUnwrap(spezi.typedCollection[LocalStorage<LocalStorageTestStandard>.self])
        
        let letter = Letter(greeting: "Hello Paul 👋\(String(repeating: "🚀", count: Int.random(in: 0...10)))")
        try localStorage.store(letter, settings: .unencrypted())
        let storedLetter: Letter = try localStorage.read(settings: .unencrypted())
        
        XCTAssertEqual(letter, storedLetter)
        
        try localStorage.delete(Letter.self)
        try localStorage.delete(storageKey: "Letter")
    }
}
