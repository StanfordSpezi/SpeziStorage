//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

/// A user's credential containing username, password and server.
@available(*, deprecated, renamed: "Credential")
public typealias Credentials = Credential

/// A user's credential containing username, password and server.
public struct Credential: Equatable, Identifiable {
    /// The username.
    public var username: String
    /// The password.
    public var password: String
    /// The server.
    public var server: String?
    
    /// Identified by the username.
    public var id: String {
        username
    }
    
    
    /// Create new credential.
    /// - Parameters:
    ///   - username: The username.
    ///   - password: The password.
    ///   - server: The server.
    public init(
        username: String,
        password: String,
        server: String? = nil
    ) {
        self.username = username
        self.password = password
        self.server = server
    }
}


extension Credential: Sendable {}
