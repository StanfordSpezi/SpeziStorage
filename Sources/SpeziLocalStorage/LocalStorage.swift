//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import Foundation
import Security
import Spezi
import SpeziSecureStorage


/// On-disk storage of data in mobile applications.
///
/// The module relies on the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage)
/// module to enable an encrypted on-disk storage as defined by the ``LocalStorageSetting`` configuration.
///
/// Use ``LocalStorage/store(_:storageKey:settings:)`` to store elements on disk and define the settings using a ``LocalStorageSetting`` instance.
///
/// Use ``LocalStorage/read(_:storageKey:settings:)`` to read elements on disk which are decoded as define by  passed in  ``LocalStorageSetting`` instance.
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
    
    
    /// The ``LocalStorage`` initializer.
    public required init() {}
    
    
    /// Store elements on disk and define the settings using a ``LocalStorageSetting`` instance.
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

        let data = try encoder.encode(element)

        
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
    
    
    /// Read elements on disk which are decoded as defined by  passed in  ``LocalStorageSetting`` instance.
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
        let fileURL = fileURL(from: storageKey, type: C.self)
        let data = try Data(contentsOf: fileURL)
        
        // Determine if the data should be decrypted or not:
        guard let keys = try settings.keys(from: secureStorage) else {
            return try decoder.decode(C.self, from: data)
        }
        
        guard SecKeyIsAlgorithmSupported(keys.privateKey, .decrypt, encryptionAlgorithm) else {
            throw LocalStorageError.decryptionNotPossible
        }

        var decryptError: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(keys.privateKey, encryptionAlgorithm, data as CFData, &decryptError) as Data? else {
            throw LocalStorageError.decryptionNotPossible
        }
        
        return try JSONDecoder().decode(C.self, from: decryptedData)
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
    /// Use ``delete(storageKey:)`` to manually define the storage key.
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
