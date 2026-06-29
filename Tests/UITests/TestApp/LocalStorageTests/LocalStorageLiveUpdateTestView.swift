//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziLocalStorage
import SwiftUI


extension LocalStorageKeys { // swiftlint:disable:this file_types_order
    static let number = LocalStorageKey<Int>("number")
}


struct LocalStorageLiveUpdateTestView: View { // swiftlint:disable:this file_types_order
    @Environment(LocalStorage.self) private var localStorage
    
    var body: some View {
        Form {
            RowView()
            Section {
                ForEach(0..<5) { number in
                    Button("\(number)") {
                        try? localStorage.store(number, for: .number)
                    }
                }
            }
        }
    }
}


struct RowView: View {
    @LocalStorageEntry(.number) private var number
    
    var body: some View {
        Section {
            LabeledContent("Number (a)", value: number.map(String.init) ?? "–")
            Button("Double Number") {
                if let number {
                    self.number = number * 2
                }
            }
        }
        Section {
            ResetNumberView(number: $number)
        }
    }
}


private struct ResetNumberView: View {
    @Binding var number: Int?
    
    var body: some View {
        LabeledContent("Number (b)", value: number.map(String.init) ?? "–")
        Button("Reset") {
            number = nil
        }
    }
}
