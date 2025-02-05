//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Defines the kind of a ``Credentials`` entry in the Credentials Storage.
public enum CredentialsKind: Hashable, Sendable {
    /// A generic username-password entry, which is not accociated with any specific server.
    case genericPassword
    /// An internet password, i.e. a username-password entry which is asspociated with a specific website.
    case internetPassword(server: String)
}
