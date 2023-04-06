//
// This source file is part of the CardinalKit open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import XCTestApp


enum CardinalKitStorageTests: String, TestAppTests {
    case localStorage = "Local Storage"
    case secureStorage = "Secure Storage"
    
    
    func view(withNavigationPath path: Binding<NavigationPath>) -> some View {
        switch self {
        case .localStorage:
            LocalStorageTestsView()
        case .secureStorage:
            SecureStorageTestsView()
        }
    }
}
