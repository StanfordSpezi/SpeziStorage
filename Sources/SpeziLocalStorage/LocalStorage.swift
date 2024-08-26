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
import SpeziSecureStorage


/// On-disk storage of data in mobile applications.
///
/// The module relies on the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage)
/// module to enable an encrypted on-disk storage. You configuration encryption using the ``LocalStorageSetting`` type.
///
/// ## Topics
///
/// ### Configuration
/// - ``init()``
///
/// ### Storing Elements
/// - ``store(_:encoder:storageKey:settings:)``
/// - ``store(_:configuration:encoder:storageKey:settings:)``
///
/// ### Loading Elements
///
/// - ``read(_:decoder:storageKey:settings:)``
/// - ``read(_:configuration:decoder:storageKey:settings:)``
///
/// ### Deleting Entries
///
/// - ``delete(_:)``
/// - ``delete(storageKey:)``
public final class LocalStorage: Module, DefaultInitializable, EnvironmentAccessible, @unchecked Sendable {
    private let encryptionAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
    @Dependency private var secureStorage = SecureStorage()
    
    
    private var localStorageDirectory: URL {
        // We store the files in the application support directory as described in
        // [File System Basics](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html).
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let localStoragePath = paths[0].appendingPathComponent("edu.stanford.spezi/LocalStorage")
        if !FileManager.default.fileExists(atPath: localStoragePath.path) {
            do {
                try FileManager.default.createDirectory(atPath: localStoragePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        return localStoragePath
    }
    
    
    /// Configure the `LocalStorage` module.
    public required init() {}
    
    
    /// Store elements on disk.
    ///
    /// ```swift
    /// struct Note: Codable, Equatable {
    ///     let text: String
    ///     let date: Date
    /// }
    ///
    /// let note = Note(text: "Spezi is awesome!", date: Date())
    ///
    /// do {
    ///     try await localStorage.store(note)
    /// } catch {
    ///     // Handle storage errors ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - element: The element that should be stored conforming to `Encodable`
    ///   - encoder: The `Encoder` to use for encoding the `element`.
    ///   - storageKey: An optional storage key to identify the file.
    ///   - settings: The ``LocalStorageSetting``s applied to the file on disk.
    public func store<C: Encodable, D: TopLevelEncoder>(
        _ element: C,
        encoder: D = JSONEncoder(),
        storageKey: String? = nil,
        settings: LocalStorageSetting = .encryptedUsingKeyChain()
    ) throws where D.Output == Data {
        try store(element, storageKey: storageKey, settings: settings) { element in
            try encoder.encode(element)
        }
    }

    /// Store elements on disk that require additional configuration for encoding.
    ///
    /// - Parameters:
    ///   - element: The element that should be stored conforming to `Encodable`
    ///   - configuration: A configuration that provides additional information for encoding.
    ///   - encoder: The `Encoder` to use for encoding the `element`.
    ///   - storageKey: An optional storage key to identify the file.
    ///   - settings: The ``LocalStorageSetting``s applied to the file on disk.
    public func store<C: EncodableWithConfiguration, D: TopLevelEncoder>(
        _ element: C,
        configuration: C.EncodingConfiguration,
        encoder: D = JSONEncoder(),
        storageKey: String? = nil,
        settings: LocalStorageSetting = .encryptedUsingKeyChain()
    ) throws where D.Output == Data {
        try store(element, storageKey: storageKey, settings: settings) { element in
            try encoder.encode(element, configuration: configuration)
        }
    }

    private func store<C>(
        _ element: C,
        storageKey: String?,
        settings: LocalStorageSetting,
        encoding: (C) throws -> Data
    ) throws {
        var fileURL = fileURL(from: storageKey, type: C.self)
        let fileExistsAlready = FileManager.default.fileExists(atPath: fileURL.path)

        // Called at the end of each execution path
        // We can not use defer as the function can potentially throw an error.
        func setResourceValues() throws {
            do {
                if settings.excludedFromBackup {
                    var resourceValues = URLResourceValues()
                    resourceValues.isExcludedFromBackup = true
                    try fileURL.setResourceValues(resourceValues)
                }
            } catch {
                // Revert a written file if it did not exist before.
                if !fileExistsAlready {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                }
                throw LocalStorageError.couldNotExcludedFromBackup
            }
        }

        let data = try encoding(element)


        // Determine if the data should be encrypted or not:
        guard let keys = try settings.keys(from: secureStorage) else {
            // No encryption:
            try data.write(to: fileURL)
            try setResourceValues()
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
    }

    
    /// Read elements from disk.
    ///
    /// ```swift
    /// do {
    ///     let storedNote: Note = try await localStorage.read()
    ///     // Do something with `storedNote`.
    /// } catch {
    ///     // Handle read errors ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type that is used to decode the data from disk.
    ///   - decoder: The `Decoder` to use to decode the stored data into the provided `type`.
    ///   - storageKey: An optional storage key to identify the file.
    ///   - settings: The ``LocalStorageSetting``s used to retrieve the file on disk.
    /// - Returns: The element conforming to `Decodable`.
    public func read<C: Decodable, D: TopLevelDecoder>(
        _ type: C.Type = C.self,
        decoder: D = JSONDecoder(),
        storageKey: String? = nil,
        settings: LocalStorageSetting = .encryptedUsingKeyChain()
    ) throws -> C where D.Input == Data {
        try read(storageKey: storageKey, settings: settings) { data in
            try decoder.decode(type, from: data)
        }
    }

    /// Read elements from disk that require additional configuration for decoding.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type that is used to decode the data from disk.
    ///   - configuration: A configuration that provides additional information for decoding.
    ///   - decoder: The `Decoder` to use to decode the stored data into the provided `type`.
    ///   - storageKey: An optional storage key to identify the file.
    ///   - settings: The ``LocalStorageSetting``s used to retrieve the file on disk.
    /// - Returns: The element conforming to `Decodable`.
    public func read<C: DecodableWithConfiguration, D: TopLevelDecoder>( // swiftlint:disable:this function_default_parameter_at_end
        _ type: C.Type = C.self,
        configuration: C.DecodingConfiguration,
        decoder: D = JSONDecoder(),
        storageKey: String? = nil,
        settings: LocalStorageSetting = .encryptedUsingKeyChain()
    ) throws -> C where D.Input == Data {
        try read(storageKey: storageKey, settings: settings) { data in
            try decoder.decode(type, from: data, configuration: configuration)
        }
    }

    private func read<C>(
        storageKey: String?,
        settings: LocalStorageSetting,
        decoding: (Data) throws -> C
    ) throws -> C {
        let fileURL = fileURL(from: storageKey, type: C.self)
        let data = try Data(contentsOf: fileURL)

        // Determine if the data should be decrypted or not:
        guard let keys = try settings.keys(from: secureStorage) else {
            return try decoding(data)
        }

        guard SecKeyIsAlgorithmSupported(keys.privateKey, .decrypt, encryptionAlgorithm) else {
            throw LocalStorageError.decryptionNotPossible
        }

        var decryptError: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(keys.privateKey, encryptionAlgorithm, data as CFData, &decryptError) as Data? else {
            throw LocalStorageError.decryptionNotPossible
        }

        return try decoding(decryptedData)
    }

    
    /// Deletes a file stored on disk identified by the `storageKey`.
    ///
    /// ```swift
    /// do {
    ///     try await localStorage.delete(storageKey: "MyNote")
    /// } catch {
    ///     // Handle delete errors ...
    /// }
    /// ```
    ///
    /// Use ``delete(_:)`` as an automatically define the `storageKey` if the type conforms to `Encodable`.
    ///
    /// - Parameters:
    ///   - storageKey: An optional storage key to identify the file.
    public func delete(storageKey: String) throws {
        try delete(String.self, storageKey: storageKey)
    }
    
    /// Deletes a file stored on disk defined by a  `Decodable` type that is used to derive the storage key.
    ///
    /// - Note: Use ``delete(storageKey:)`` to manually define the storage key.
    ///
    /// - Parameters:
    ///   - type: The `Encodable` type that is used to store the type originally.
    public func delete<C: Encodable>(_ type: C.Type = C.self) throws {
        try delete(C.self, storageKey: nil)
    }
    
    
    private func delete<C: Encodable>(
        _ type: C.Type = C.self,
        storageKey: String? = nil
    ) throws {
        let fileURL = self.fileURL(from: storageKey, type: C.self)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch {
                throw LocalStorageError.deletionNotPossible
            }
        }
    }
    
    private func fileURL<C>(from storageKey: String? = nil, type: C.Type = C.self) -> URL {
        let storageKey = storageKey ?? String(describing: C.self)
        return localStorageDirectory.appending(path: storageKey).appendingPathExtension("localstorage")
    }
}
