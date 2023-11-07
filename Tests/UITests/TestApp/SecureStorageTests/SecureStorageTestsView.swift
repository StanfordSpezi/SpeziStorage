//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziSecureStorage
import SwiftUI
import XCTestApp


struct SecureStorageTestsView: View {
    @Environment(SecureStorage.self) var secureStorage
    
    
    var body: some View {
        TestAppView(testCase: SecureStorageTests(secureStorage: secureStorage))
    }
}
