//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Identifies Keys used with the ``CredentialsStorage`` module.
public struct KeyTag: RawRepresentable, Hashable, Sendable {
    /// The Key Tag's raw string value
    public let rawValue: String
    
    /// Creates a new Key Tag
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Creates a new Key Tag
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}
