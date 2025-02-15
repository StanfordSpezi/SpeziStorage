//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Used by ``CredentialsTag`` to define the kind of a ``Credentials`` entry in the keychain storage.
public enum CredentialsKind: Hashable, Sendable {
    /// A generic username-password entry, which is not associated with any specific server.
    case genericPassword(service: String)
    /// An internet password, i.e. a username-password entry which is associated with a specific website.
    case internetPassword(server: String)
}
