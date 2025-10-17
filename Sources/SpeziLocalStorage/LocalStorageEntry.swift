//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import SwiftUI


/// Access ``LocalStorage`` entries within a SwiftUI View.
///
/// The property wrapper will automatically trigger a view update when the key's value in the ``LocalStorage`` changes.
///
/// Example:
/// ```swift
/// struct Person: Codable {
///     let age: Int
///     let name: String
/// }
///
/// extension LocalStorageKeys {
///     static let lastUser = LocalStorageKey<Person>("edu.stanford.spezi.app.lastUser")
/// }
///
/// struct ExampleView: View {
///     @LocalStorageEntry(.lastUser)
///     private var lastUser
///
///     var body: some View {
///         if let lastUser {
///             UserDetailsView(lastUser)
///         } else {
///             ContentUnavailableView("No last user", image: "person.slash")
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct LocalStorageEntry<Value>: DynamicProperty { // swiftlint:disable:this file_types_order
    private let key: LocalStorageKey<Value>
    
    @Environment(LocalStorage.self) private var localStorage
    @State private var internals = LocalStorageEntryInternals<Value>()
    
    public var wrappedValue: Value? {
        get { internals.value }
        nonmutating set {
            if let newValue = newValue as? any Equatable, newValue.isEqual(internals.value as Any) {
                // don't persist the same value again
            } else {
                try? localStorage.store(newValue, for: key)
            }
        }
    }
    
    /// Creates a new `LocalStorageEntry` for the specified storage key
    public init(_ key: LocalStorageKey<Value>) {
        self.key = key
    }
    
    @_documentation(visibility: internal)
    public func update() {
        internals.subscribe(to: key, in: localStorage)
    }
}


@Observable
private final class LocalStorageEntryInternals<Value> {
    fileprivate var value: Value?
    @ObservationIgnored private var key: LocalStorageKey<Value>?
    @ObservationIgnored private var localStorage: LocalStorage?
    @ObservationIgnored private var cancellable: AnyCancellable?
    
    func subscribe(to key: LocalStorageKey<Value>, in localStorage: LocalStorage) {
        if self.key === key, self.localStorage === localStorage, cancellable != nil {
            return
        }
        cancellable?.cancel()
        self.key = key
        self.localStorage = localStorage
        cancellable = key.publisher.sink { [weak self] newValue in
            self?.value = newValue
        }
        value = try? localStorage.load(key)
    }
}


extension Equatable {
    func isEqual(_ other: Any) -> Bool {
        if let other = other as? Self {
            self == other
        } else {
            false
        }
    }
}
