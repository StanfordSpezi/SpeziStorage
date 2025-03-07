//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class KeychainStorageTests: XCTestCase {
    @MainActor
    func testKeychainStorage() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Keychain Storage"].tap()
        
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
}
