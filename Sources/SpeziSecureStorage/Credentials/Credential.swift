//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// A user's credential containing username and password.
@available(*, deprecated, renamed: "Credential")
public typealias Credentials = Credential

/// A user's credential containing username and password.
public struct Credential: Equatable, Identifiable {
    /// The username.
    public var username: String
    /// The password.
    public var password: String
    
    
    /// Identified by the username.
    public var id: String {
        username
    }
    
    
    /// Create new credential.
    /// - Parameters:
    ///   - username: The username.
    ///   - password: The password.
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}


extension Credential: Sendable {}
