//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Security


/// An `Error` thrown by the `SecureStorage` module.
public enum SecureStorageError: Error {
    /// Creation of a new element failed with a `CFError`.
    case createFailed(CFError? = nil)
    case notFound
    /// The error is thrown if an entitlement is missing to use the KeyChain.
    /// Refer to
    /// [Using the keychain to manage user secrets](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets)
    /// about more information about the KeyChain services.
    ///
    /// If you try to use an access group to which your app doesn't belong, the operation also fails and returns the `missingEntitlement` error.
    /// Please refer to
    /// [Sharing access to keychain items among a collection of apps](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)
    /// for more information about KeyChain access groups.
    /// Remove the  ``SecureStorageScope``'s `accessGroup` configuration value if you do not intend to use KeyChain access groups.
    case missingEntitlement
    /// The `SecureStorage` module is unable to decode the information obtained into a credentials.
    case unexpectedCredentialsData
    /// The `SecureStorage` module encountered a Keychain error when interacting with the Keychain.
    case keychainError(status: OSStatus)
}
