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
public struct LocalStorageEntry<Value: Sendable>: DynamicProperty, Sendable { // swiftlint:disable:this file_types_order
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
    
    public var projectedValue: Binding<Value?> {
        Binding<Value?> {
            self.wrappedValue
        } set: {
            self.wrappedValue = $0
        }
    }
    
    /// Creates a new `LocalStorageEntry` for the specified storage key
    public init(_ key: LocalStorageKey<Value>) {
        self.key = key
    }
    
    @_documentation(visibility: internal)
    public func update() {
        Task {
            // we sometimes get "precondition failure: setting value during update" crashes in the subscribe call on iOS 26;
            // this is our way of hopefully avoiding this
            await Task.yield()
            internals.subscribe(to: key, in: localStorage)
        }
    }
}


@Observable
private final class LocalStorageEntryInternals<Value> {
    fileprivate private(set) var value: Value?
    
    @ObservationIgnored private var cancellable: AnyCancellable?
    
    func subscribe(to key: LocalStorageKey<Value>, in localStorage: LocalStorage) {
        cancellable?.cancel()
        cancellable = key.publisher.sink { [weak self] newValue in
            self?.value = newValue
        }
        value = try? localStorage.load(key)
    }
}

extension LocalStorageEntryInternals: @unchecked Sendable where Value: Sendable {}


extension Equatable {
    func isEqual(_ other: Any) -> Bool {
        if let other = other as? Self {
            self == other
        } else {
            false
        }
    }
}
