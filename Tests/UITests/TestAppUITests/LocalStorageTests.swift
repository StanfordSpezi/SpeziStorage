//
// This source file is part of the Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class LocalStorageTests: XCTestCase {
    func testLocalStorage() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.staticTexts["Local Storage"].tap()
        
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
}
