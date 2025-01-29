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
    
    public init(_ key: LocalStorageKey<Value>) {
        self.key = key
    }
    
    public func update() {
        internals.subscribe(to: key, in: localStorage)
    }
}


@Observable
private final class LocalStorageEntryInternals<Value> {
    fileprivate var value: Value?
    
    @ObservationIgnored private var cancellable: AnyCancellable?
    
    func subscribe(to key: LocalStorageKey<Value>, in localStorage: LocalStorage) {
        cancellable?.cancel()
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
