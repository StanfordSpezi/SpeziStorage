//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class SecureStorageTests: XCTestCase {
    @MainActor
    func testSecureStorage() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Secure Storage"].tap()
        
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
}
