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
///     static let note = LocalStorageKey<Note>("edu.stanford.spezi.exampleNote")
///     static let person = LocalStorageKey<Person>("edu.stanford.spezi.examplePerson", encoder: PropertyListEncoder(), decoder: PropertyListDecoder())
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
public final class LocalStorageKey<Value>: LocalStorageKeys, @unchecked Sendable { // swiftlint:disable:this file_types_order
    let key: String
    let setting: LocalStorageSetting
    private let encodeImp: @Sendable (Value, Any?) throws -> Data
    private let decodeImp: @Sendable (Data, Any?) throws -> Value?
    private let lock = RWLock()
    private let subject = PassthroughSubject<Value?, Never>()
    
    var publisher: some Publisher<Value?, Never> { subject }
    
    private init(
        key: String,
        setting: LocalStorageSetting,
        encode: @Sendable @escaping (Value, Any?) throws -> Data,
        decode: @Sendable @escaping (Data, Any?) throws -> Value?
    ) {
        self.key = key
        self.setting = setting
        self.encodeImp = encode
        self.decodeImp = decode
    }
    
    /// Creates a Local Storage Key that uses custom encoding and decoding functions.
    public init(
        key: String,
        setting: LocalStorageSetting = .default,
        encode: @Sendable @escaping (Value) throws -> Data,
        decode: @Sendable @escaping (Data) throws -> Value?
    ) {
        self.key = key
        self.setting = setting
        self.encodeImp = { value, _ in try encode(value) }
        self.decodeImp = { data, _ in try decode(data) }
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
    
    /// Encodes a `Value` into `Data`.
    /// - parameter value: the to-be-encoded value
    /// - parameter context: optional context which should be passed to the encoding operation. This is intended for passing e.g. an encoding configuration. The caller is responsible for ensuring that the passed-in value is compatible with the specific LocalStorageKey's encoding operation.
    func encode(_ value: Value, context: (some Any)?) throws -> Data {
        try encodeImp(value, context)
    }
    
    /// Decodes a `Value` from `Data`.
    /// - parameter data: the to-be-decoded data
    /// - parameter context: optional context which should be passed to the decoding operation. This is intended for passing e.g. an decoding configuration. The caller is responsible for ensuring that the passed-in value is compatible with the specific LocalStorageKey's decoding operation.
    func decode(from data: Data, context: (some Any)?) throws -> Value? {
        try decodeImp(data, context)
    }
}


extension LocalStorageSetting { // swiftlint:disable:this file_types_order
    /// The default storage setting.
    public static var `default`: Self { .encryptedUsingKeychain() }
}


extension LocalStorageKey { // swiftlint:disable:this file_types_order
    /// Creates a Local Storage Key that uses JSON to encode and decode its entries.
    public convenience init(_ key: String, setting: LocalStorageSetting = .default) where Value: Codable {
        self.init(key, setting: setting, encoder: JSONEncoder(), decoder: JSONDecoder())
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
    
    /// Creates a Local Storage Key for storing values that are either `Encodable`, or `EncodableWithConfiguration`, or both, and `Decodable`, or `DecodableWithConfiguration`, or both.
    /// - Important: The caller is responsible for ensuring that these conformance requirements are met.
    private convenience init<E, D>(
        codableOrCodableWithConfig_ key: String,
        setting: LocalStorageSetting,
        encoder: E,
        decoder: D
    ) where E: SpeziFoundation.TopLevelEncoder & Sendable, D: SpeziFoundation.TopLevelDecoder & Sendable, E.Output == Data, D.Input == Data {
        self.init(key: key, setting: setting) { (value: Value, context: Any?) -> Data in
            if let value = value as? any EncodableWithConfiguration {
                do {
                    return try encoder.encode(value, configuration: context as Any)
                } catch is InvalidCodableWithConfigurationInput {
                    // we want to "fall through" to the "if is Encodable" check below in this case
                } catch {
                    throw error
                }
            }
            if let value = value as? any Encodable {
                return try encoder.encode(value)
            }
            // should be unreachable, since this initializer is only used by initializers which themselves
            // require `Value` be either `Encodable`, or `EncodableWithConfiguration`, or both.
            preconditionFailure("Input type ('\(Value.self)') is neither \((any Encodable).self) nor \((any EncodableWithConfiguration).self)")
        } decode: { (data: Data, context: Any?) in
            if let type = Value.self as? any DecodableWithConfiguration.Type {
                do {
                    // SAFETY: the force cast here is fine since we know that the type will match, because the `type` we're passing in
                    // (and which will be returned from the decode(:from:configuration:) call) is really just `Value` cast to an existential of the
                    // `DecodableWithConfiguration` protocol.
                    return try decoder.decode(type, from: data, configuration: context as Any) as! Value? // swiftlint:disable:this force_cast
                } catch is InvalidCodableWithConfigurationInput {
                    // we want to "fall through" to the "if is Codable" check below in this case
                } catch {
                    throw error
                }
            }
            if let type = Value.self as? any Decodable.Type {
                // SAFETY: the force cast here is fine since we know that the type will match, because the `type` we're passing in
                // (and which will be returned from the decode(:from:configuration:) call) is really just `Value` cast to an existential of the
                // `Decodable` protocol.
                return try decoder.decode(type, from: data) as! Value? // swiftlint:disable:this force_cast
            }
            // should be unreachable, since this initializer is only used by initializers which themselves
            // require `Value` be either `Decodable`, or `DecodableWithConfiguration`, or both.
            preconditionFailure("Input type ('\(Value.self)') is neither \((any Decodable).self) nor \((any DecodableWithConfiguration).self)")
        }
    }
    
    /// Creates a Local Storage Key for a type that is `Codable`, that uses a custom encoder and decoder.
    @_disfavoredOverload
    public convenience init<E: SpeziFoundation.TopLevelEncoder & Sendable, D: SpeziFoundation.TopLevelDecoder & Sendable>(
        _ key: String,
        setting: LocalStorageSetting = .default, // swiftlint:disable:this function_default_parameter_at_end
        encoder: E,
        decoder: D
    ) where Value: Codable, E.Output == Data, D.Input == Data {
        self.init(codableOrCodableWithConfig_: key, setting: setting, encoder: encoder, decoder: decoder)
    }
    
    /// Creates a Local Storage Key for a type that is `CodableWithConfiguration`, that uses a custom encoder and decoder.
    public convenience init<E: SpeziFoundation.TopLevelEncoder & Sendable, D: SpeziFoundation.TopLevelDecoder & Sendable>(
        _ key: String,
        setting: LocalStorageSetting = .default, // swiftlint:disable:this function_default_parameter_at_end
        encoder: E,
        decoder: D
    ) where Value: CodableWithConfiguration, E.Output == Data, D.Input == Data {
        self.init(codableOrCodableWithConfig_: key, setting: setting, encoder: encoder, decoder: decoder)
    }
}


private struct InvalidCodableWithConfigurationInput: Error {
    init() {}
}

extension SpeziFoundation.TopLevelEncoder {
    /// Tries to encode the value, using the specified configuration.
    /// - throws: `InvalidCodableWithConfigurationInput` if `configuration` was not a valid input. Any other errors are thrown by the underlying encode operation.
    @_disfavoredOverload
    fileprivate func encode<T: EncodableWithConfiguration>(_ value: T, configuration: Any) throws -> Output {
        guard let configuration = configuration as? T.EncodingConfiguration else {
            throw InvalidCodableWithConfigurationInput()
        }
        return try self.encode(value, configuration: configuration)
    }
}


extension SpeziFoundation.TopLevelDecoder {
    /// Tries to decode the value, using the specified configuration.
    /// - throws: `InvalidCodableWithConfigurationInput` if `configuration` was not a valid input. Any other errors are thrown by the underlying decode operation.
    @_disfavoredOverload
    fileprivate func decode<T: DecodableWithConfiguration>(
        _ type: T.Type,
        from input: Input,
        configuration: Any
    ) throws -> T {
        guard let configuration = configuration as? T.DecodingConfiguration else {
            throw InvalidCodableWithConfigurationInput()
        }
        return try self.decode(type, from: input, configuration: configuration)
    }
}
