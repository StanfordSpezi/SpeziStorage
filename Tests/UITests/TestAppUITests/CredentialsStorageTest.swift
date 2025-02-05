//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class CredentialsStorageTests: XCTestCase {
    @MainActor
    func testCredentialsStorage() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Credentials Storage"].tap()
        
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
}
