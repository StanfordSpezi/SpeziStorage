//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class LocalStorageTests: XCTestCase {
    @MainActor
    func testLocalStorage() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Local Storage"].tap()
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
    
    
    @MainActor
    func testLocalStorageLiveUpdates() async throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Local Storage (Live Update)"].tap()
        try await Task.sleep(for: .seconds(0.5))
        
        let numbers = (0..<17).map { _ in Int.random(in: 0..<5) }
        for number in numbers {
            app.buttons["\(number)"].tap()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "number.*\(number)")).element.waitForExistence(timeout: 0.5))
        }
    }
}
