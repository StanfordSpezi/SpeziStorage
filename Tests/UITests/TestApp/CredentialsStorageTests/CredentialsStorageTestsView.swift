//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziCredentialsStorage
import SwiftUI
import XCTestApp


struct CredentialsStorageTestsView: View {
    @Environment(CredentialsStorage.self) var credentialsStorage
    
    
    var body: some View {
        TestAppView(testCase: CredentialsStorageTests(credentialsStorage: credentialsStorage))
    }
}
