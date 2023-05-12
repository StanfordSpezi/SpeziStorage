//
// This source file is part of the Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziSecureStorage
import SwiftUI
import XCTestApp


struct SecureStorageTestsView: View {
    @EnvironmentObject var secureStorage: SecureStorage<TestAppStandard>
    
    
    var body: some View {
        TestAppView(testCase: SecureStorageTests(secureStorage: secureStorage))
    }
}
