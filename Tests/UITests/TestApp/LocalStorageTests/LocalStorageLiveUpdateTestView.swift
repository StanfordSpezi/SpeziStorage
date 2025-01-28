//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziLocalStorage
import SwiftUI


extension LocalStorageKeys {
    static let number = LocalStorageKey<Int>("number")
}


struct LocalStorageLiveUpdateTestView: View {
    @Environment(LocalStorage.self) private var localStorage
    
    var body: some View {
        Form {
            RowView()
            Section {
                ForEach(0..<5) { number in
                    Button("\(number)") {
                        try! localStorage.store(number, for: .number)
                    }
                }
            }
        }
    }
}


struct RowView: View {
    @LocalStorageEntry(.number)
    private var number
    
    var body: some View {
        LabeledContent("number", value: number.map(String.init) ?? "–")
    }
}

