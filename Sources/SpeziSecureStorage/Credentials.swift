//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A pair of username and password credentials.
public struct Credentials: Equatable, Identifiable {
    /// The username.
    public var username: String
    /// The password.
    public var password: String
    
    
    /// Identified by the username.
    public var id: String {
        username
    }
    
    
    /// Create new credentials.
    /// - Parameters:
    ///   - username: The username.
    ///   - password: The password.
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}


extension Credentials: Sendable {}
