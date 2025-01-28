//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import Foundation
import SpeziFoundation


/// Used to statically define ``LocalStorageKey``s.
///
/// - Important: Your code does not use this type directly, apart from extending it when defining storage keys.
public class LocalStorageKeys {
    fileprivate init() {}
}


/// Type-safe key for ``LocalStorage``.
///
/// `LocalStorageKey` objects are used to define how data is stored to and loaded from the ``LocalStorage`` module.
///
/// The `LocalStorageKey` defines how and where data associated with the key is stored, encoded, and decoded.
/// It furthermore acts as a lock when accessing data from a ``LocalStorage``.
///
/// - Important: All `LocalStorageKey`s used in an application must have unique, stable underlying `key`s.
/// Defining and using two or more `LocalStorageKey`s with identical underlying `key`s will lead to conflicts and data loss or corruption.
/// It is advised that you use a reverse-DNS-style naming scheme for your keys, in order to avoid name collisions.
///
/// ### Supported Types
/// - `Codable` types
/// - `NSSecureCoding`-compliant types
/// - Raw `Data` objects
/// - Any other type (requires providing custom encoding and decoding handlers)
///
/// ### Example
/// ```swift
/// struct Note: Codable {
///     let date: Date
///     let text: String
/// }
///
/// struct Person: Codable {
///     let name: String
///     let dateOfBirth: DateComponents
/// }
///
/// extension LocalStorageKeys {
///     static let note = LocalStorageKey<Note>("note")
///     static let person = LocalStorageKey<Person>("person", encoder: PropertyListEncoder(), decoder: PropertyListDecoder())
/// }
/// ```
///
/// ## Topics
/// ### Creating Storage Keys
/// - ``init(_:setting:)-21oqu``
/// - ``init(_:setting:encoder:decoder:)``
/// - ``init(_:setting:)-1sf9p``
/// - ``init(_:setting:)-9t3s8``
/// - ``init(key:setting:encode:decode:)``
///
/// ### Other
/// - ``LocalStorageKeys``
public final class LocalStorageKey<Value>: LocalStorageKeys, @unchecked Sendable {
    let key: String
    let setting: LocalStorageSetting
    let encode: @Sendable (Value) throws -> Data
    let decode: @Sendable (Data) throws -> Value?
    private let lock = RWLock()
    private let subject = PassthroughSubject<Value?, Never>()
    
    var publisher: AnyPublisher<Value?, Never> { subject.eraseToAnyPublisher() }
    
    /// Creates a Local Storage Key that uses custom encoding and decoding functions.
    public init(
        key: String,
        setting: LocalStorageSetting = .default,
        encode: @Sendable @escaping (Value) throws -> Data,
        decode: @Sendable @escaping (Data) throws -> Value?
    ) {
        self.key = key
        self.setting = setting
        self.encode = encode
        self.decode = decode
    }
    
    func withReadLock<Result>(_ block: () throws -> Result) rethrows -> Result {
        try lock.withReadLock(body: block)
    }
    
    func withWriteLock<Result>(_ block: () throws -> Result) rethrows -> Result {
        try lock.withWriteLock(body: block)
    }
    
    func informSubscribersAboutNewValue(_ newValue: Value?) {
        subject.send(newValue)
    }
}


extension LocalStorageKey {
    /// Creates a Local Storage Key that uses JSON to encode and decode its entries.
    public convenience init(_ key: String, setting: LocalStorageSetting = .default) where Value: Codable {
        self.init(key, setting: setting, encoder: JSONEncoder(), decoder: JSONDecoder())
    }
    
    /// Creates a Local Storage Key that uses a custom encoder and decoder.
    public convenience init<E: SpeziFoundation.TopLevelEncoder & Sendable, D: SpeziFoundation.TopLevelDecoder & Sendable>(
        _ key: String,
        setting: LocalStorageSetting = .default, // swiftlint:disable:this function_default_parameter_at_end
        encoder: E,
        decoder: D
    ) where Value: Codable, E.Output == Data, D.Input == Data {
        self.init(key: key, setting: setting) { value in
            try encoder.encode(value)
        } decode: { data in
            try decoder.decode(Value.self, from: data)
        }
    }
    
    /// Creates a Local Storage Key for storing and loading `NSSecureCoding`-compliant objects.
    public convenience init(_ key: String, setting: LocalStorageSetting = .default) where Value: NSObject & NSSecureCoding {
        self.init(key: key, setting: setting) { value in
            try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
        } decode: { data in
            try NSKeyedUnarchiver.unarchivedObject(ofClass: Value.self, from: data)
        }
    }
    
    /// Creates a Local Storage Key for storing and loading `Data` objects.
    ///
    /// This initializer allows more efficient persistance: if the value is already `Data`, there is no need to perform a dedicated encoding or decoding step.
    public convenience init(_ key: String, setting: LocalStorageSetting = .default) where Value == Data {
        self.init(key: key, setting: setting, encode: { $0 }, decode: { $0 })
    }
}


extension LocalStorageSetting {
    /// The default storage setting.
    public static var `default`: Self { .encryptedUsingKeyChain() }
}
