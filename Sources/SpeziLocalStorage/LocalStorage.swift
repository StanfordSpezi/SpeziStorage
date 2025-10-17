//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Security
import Spezi
import SpeziFoundation
import SpeziKeychainStorage


/// Encrypted on-disk storage of data in mobile applications.
///
/// You interact with the ``LocalStorage`` API by defining custom ``LocalStorageKey``s, which are used to store values into the storage, and fetch them.
/// The key also allows you to define how each individual entry should be stored: e.g., which encoding and encryption settings should be used.
///
/// ## Topics
///
/// ### Configuration
/// - ``init()``
///
/// ### Storing Elements
/// - ``store(_:for:)``
/// - ``store(_:for:configuration:)``
/// - ``modify(_:_:)``
/// - ``modify(_:decodingConfiguration:encodingConfiguration:_:)``
///
/// ### Loading Elements
/// - ``load(_:)``
/// - ``load(_:configuration:)``
///
/// ### Deleting Entries
/// - ``delete(_:)``
/// - ``deleteAll()``
public final class LocalStorage: Module, DefaultInitializable, EnvironmentAccessible, @unchecked Sendable {
    @Dependency(KeychainStorage.self) private var keychainStorage
    @Application(\.logger) private var logger
    
    private let fileManager = FileManager.default
    /* private-but-tests */ let localStorageDirectory: URL
    private let encryptionAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
    
    
    /// Configure the `LocalStorage` module.
    public required init() {
        // We store the files in the application support directory as described in
        // [File System Basics](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html).
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        localStorageDirectory = paths[0].appendingPathComponent("edu.stanford.spezi/LocalStorage")
    }
    
    
    @_documentation(visibility: internal)
    public func configure() {
        do {
            try createLocalStorageDirectoryIfNecessary()
        } catch {
            logger.error("Unable to create LocalStorage directory: \(error)")
        }
    }
    
    
    private func createLocalStorageDirectoryIfNecessary() throws {
        guard !fileManager.fileExists(atPath: localStorageDirectory.path) else {
            return
        }
        try fileManager.createDirectory(atPath: localStorageDirectory.path, withIntermediateDirectories: true, attributes: nil)
    }
    
    
    // MARK: Store
    
    /// Put a value into the `LocalStorage`.
    ///
    /// - parameter value: The value which should be persisted. Passing `nil` will delete the most-recently-stored value.
    /// - parameter key: The ``LocalStorageKey`` with which the value should be associated.
    ///
    /// - Note: This operation will overwrite any previously-stored values for this key.
    public func store<Value>(_ value: Value?, for key: LocalStorageKey<Value>) throws {
        try key.withWriteLock {
            if let value {
                try storeImp(value, for: key, context: Void?.none)
            } else {
                try deleteImp(key)
            }
        }
    }
    
    /// Put a value into the `LocalStorage`.
    ///
    /// - parameter value: The value which should be persisted. Passing `nil` will delete the most-recently-stored value.
    /// - parameter key: The ``LocalStorageKey`` with which the value should be associated.
    ///
    /// - Note: This operation will overwrite any previously-stored values for this key.
    public func store<Value>(
        _ value: Value?,
        for key: LocalStorageKey<Value>,
        configuration: Value.EncodingConfiguration
    ) throws where Value: EncodableWithConfiguration {
        try key.withWriteLock {
            if let value {
                try storeImp(value, for: key, context: configuration)
            } else {
                try deleteImp(key)
            }
        }
    }
    
    
    /// - invariant: assumes that the key's write lock is held.
    private func storeImp<Value>(_ value: Value, for key: LocalStorageKey<Value>, context: some Any) throws {
        var fileURL = fileURL(for: key)
        let fileExistsAlready = fileManager.fileExists(atPath: fileURL.path)

        // Called at the end of each execution path
        // We can not use defer as the function can potentially throw an error.
        func setResourceValues() throws {
            do {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = key.setting.isExcludedFromBackup
                try fileURL.setResourceValues(resourceValues)
            } catch {
                // Revert a written file if it did not exist before.
                if !fileExistsAlready {
                    try fileManager.removeItem(atPath: fileURL.path)
                }
                throw LocalStorageError.failedToExcludeFromBackup
            }
        }

        let data = try key.encode(value, context: context)

        // Determine if the data should be encrypted or not:
        guard let keys = try key.setting.keys(from: keychainStorage) else {
            // No encryption:
            try data.write(to: fileURL)
            try setResourceValues()
            key.informSubscribersAboutNewValue(value)
            return
        }

        // Encryption enabled:
        guard SecKeyIsAlgorithmSupported(keys.publicKey, .encrypt, encryptionAlgorithm) else {
            throw LocalStorageError.encryptionNotPossible
        }

        var encryptError: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(keys.publicKey, encryptionAlgorithm, data as CFData, &encryptError) as Data? else {
            throw LocalStorageError.encryptionNotPossible
        }

        try encryptedData.write(to: fileURL)
        try setResourceValues()
        key.informSubscribersAboutNewValue(value)
    }
    
    
    // MARK: Load
    
    /// Load a value from the `LocalStorage`.
    ///
    /// - parameter key: The ``LocalStorageKey`` associated with the to-be-retrieved value.
    /// - returns: The most recent stored value associated with the key; `nil` if no such value exists.
    public func load<Value>(_ key: LocalStorageKey<Value>) throws -> Value? {
        try key.withReadLock {
            try readImp(key, context: Void?.none)
        }
    }
    
    /// Load a value from the `LocalStorage`.
    ///
    /// - parameter key: The ``LocalStorageKey`` associated with the to-be-retrieved value.
    /// - parameter configuration: The decoding configuration which should be used when decoding a value.
    /// - returns: The most recent stored value associated with the key; `nil` if no such value exists.
    public func load<Value>(
        _ key: LocalStorageKey<Value>,
        configuration: Value.DecodingConfiguration
    ) throws -> Value? where Value: DecodableWithConfiguration {
        try key.withReadLock {
            try readImp(key, context: configuration)
        }
    }
    
    
    /// Determines whether the `LocalStorage` contains a value for the specified key.
    public func hasEntry(for key: LocalStorageKey<some Any>) -> Bool {
        key.withReadLock {
            fileManager.fileExists(atPath: fileURL(for: key).path)
        }
    }
    
    
    /// - invariant: assumes that the key's read lock is held.
    private func readImp<Value>(_ key: LocalStorageKey<Value>, context: some Any) throws -> Value? {
        let fileURL = fileURL(for: key)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)

        // Determine if the data should be decrypted or not:
        guard let keys = try key.setting.keys(from: keychainStorage) else {
            return try key.decode(from: data, context: context)
        }

        guard SecKeyIsAlgorithmSupported(keys.privateKey, .decrypt, encryptionAlgorithm) else {
            throw LocalStorageError.decryptionNotPossible
        }

        var decryptError: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(keys.privateKey, encryptionAlgorithm, data as CFData, &decryptError) as Data? else {
            throw LocalStorageError.decryptionNotPossible
        }

        return try key.decode(from: decryptedData, context: context)
    }
    
    
    // MARK: Delete
    
    /// Deletes the `LocalStorage` entry associated with `key`.
    ///
    /// ```swift
    /// do {
    ///     try localStorage.delete(.myStorageKey)
    /// } catch {
    ///     // Handle delete errors ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The ``LocalStorageKey`` identifying the entry which should be deleted.
    public func delete(_ key: LocalStorageKey<some Any>) throws {
        try key.withWriteLock {
            try deleteImp(key)
        }
    }
    
    
    /// - invariant: assumes that the key's write lock is held
    private func deleteImp(_ key: LocalStorageKey<some Any>) throws {
        let fileURL = fileURL(for: key)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(atPath: fileURL.path)
                key.informSubscribersAboutNewValue(nil)
            } catch {
                throw LocalStorageError.deletionNotPossible
            }
        }
    }
    
    
    /// Deletes all data currently stored using the `LocalStorage` API.
    ///
    /// - Warning: This will delete all data currently stored using the `LocalStorage` API.
    /// - Note: This operation is not synchronized with reads or writes on individual storage keys.
    public func deleteAll() throws {
        try fileManager.removeItem(at: localStorageDirectory)
        try createLocalStorageDirectoryIfNecessary()
    }
    
    
    // MARK: Other
    
    /// Modify a stored value in place
    ///
    /// Use this function to perform an atomic mutation of an entry in the `LocalStorage`.
    ///
    /// - parameter key: The ``LocalStorageKey`` whose value should be mutated.
    /// - parameter transform: A mapping closure, which will be called with the current value stored for `key` (or `nil`, if no value is stored).
    ///     The value after the closure invocation will be stored into the `LocalStorage`, for the entry identified by `key`.
    ///     If the closure sets `value` to `nil`, the entry will be removed from the `LocalStorage`.
    ///
    /// - throws: if `transform` throws,
    public func modify<Value>(_ key: LocalStorageKey<Value>, _ transform: (_ value: inout Value?) throws -> Void) throws {
        try key.withWriteLock {
            var value = try readImp(key, context: Void?.none)
            try transform(&value)
            if let value {
                try storeImp(value, for: key, context: Void?.none)
            } else {
                try deleteImp(key)
            }
        }
    }
    
    
    /// Modify a stored value in place
    ///
    /// Use this function to perform an atomic mutation of an entry in the `LocalStorage`.
    ///
    /// - parameter key: The ``LocalStorageKey`` whose value should be mutated.
    /// - parameter transform: A mapping closure, which will be called with the current value stored for `key` (or `nil`, if no value is stored).
    ///     The value after the closure invocation will be stored into the `LocalStorage`, for the entry identified by `key`.
    ///     If the closure sets `value` to `nil`, the entry will be removed from the `LocalStorage`.
    ///
    /// - throws: if `transform` throws,
    public func modify<Value: CodableWithConfiguration>(
        _ key: LocalStorageKey<Value>,
        decodingConfiguration: Value.DecodingConfiguration,
        encodingConfiguration: Value.EncodingConfiguration,
        _ transform: (_ value: inout Value?) throws -> Void
    ) throws {
        try key.withWriteLock {
            var value = try readImp(key, context: decodingConfiguration)
            try transform(&value)
            if let value {
                try storeImp(value, for: key, context: encodingConfiguration)
            } else {
                try deleteImp(key)
            }
        }
    }
    
    
    // MARK: File Handling
    
    func fileURL(for storageKey: LocalStorageKey<some Any>) -> URL {
        let storageKey = storageKey.key
        return localStorageDirectory.appending(path: storageKey).appendingPathExtension("localstorage")
    }
}
