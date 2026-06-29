//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class LocalStorageTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    
    @MainActor
    func testLocalStorage() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Local Storage"].tap()
        XCTAssertTrue(app.staticTexts["Passed"].waitForExistence(timeout: 2))
    }
    
    
    @MainActor
    func testLocalStorageLiveUpdates() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Local Storage (Live Update)"].tap()
        
        func assertNumberEquals(_ expected: Int?, file: StaticString = #filePath, line: UInt = #line) {
            for title in ["Number (a)", "Number (b)"] {
                let label = app.staticTexts["\(title), \(expected?.description ?? "–")"]
                XCTAssert(label.waitForExistence(timeout: 1), file: file, line: line)
            }
        }
        
        let numbers = (0..<17).map { _ in Int.random(in: 0..<5) }
        for number in numbers {
            app.buttons["\(number)"].tap()
            assertNumberEquals(number)
        }
        app.buttons["Double Number"].tap()
        assertNumberEquals(numbers[numbers.endIndex - 1] * 2)
        
        app.buttons["Reset"].tap()
        assertNumberEquals(nil)
        
        app.buttons["4"].tap()
        assertNumberEquals(4)
    }
}
