# ``SpeziKeychainStorage``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Securely store small chunks of data, such as credentials and cryptographic keys.


## Overview

The `KeychainStorage` module allows for the encrypted storage of small chunks of sensitive user data, such as usernames and passwords for internet services,
using Apple's [Keychain](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets). 

Credentials can be stored in the system keychain, and optionally synchronized across multiple devices.
Cryptographic keys can be stored in the system keychain, or if available the Secure Enclave.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

> Important: If you use the ``KeychainStorage`` on the macOS platform, ensure to add the [`Keychain Access Groups` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/keychain-access-groups) to the enclosing Xcode project via *PROJECT_NAME > Signing&Capabilities > + Capability*. The array of keychain groups can be left empty, only the base entitlement is required.

You can configure the ``KeychainStorage`` module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

```swift
import Spezi
import SpeziKeychainStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            KeychainStorage()
            // ...
        }
    }
}
```

You can then use the `KeychainStorage` class in any SwiftUI view.

```swift
struct ExampleStorageView: View {
    @Environment(KeychainStorage.self) var keychain

    var body: some View {
        // ...
    }
}
```

Alternatively, it is common to use the `KeychainStorage` module in other modules as a dependency: [Spezi Module dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module-dependency).


## Using the KeychainStorage Module

You use the `KeychainStorage` module to store, update, retrieve, and delete credentials and cryptographic keys.


### Storing Credentials

The `KeychainStorage` module enables the storage of credentials in the Keychain.

There are two kinds of credentials supported by `KeychainStorage`:
1. Generic Credentials: these are credentials which associated with some service, instead of a specific internet server;
2. Internet Credentials: these are credentials which are associated with a specific internet website, identified by a server address.

Credentials are defined using the ``CredentialsTag`` type, which specifies the kind of credential, and optionally lets you define how entries using this tag should be stored and when they should be accessible:

```swift
extension CredentialsTag {
    static let stanfordSUNet = Self.internetPassword(
        forServer: "stanford.edu",
        storage: .keychainSynchronizable
    )

    static let syncCredentials = Self.genericPassword(
        forService: "my-internal-sync-service",
        storage: .keychainSynchronizable
    )
}
```

Credentials entries in the keychain are identified by their tag and username.


You use ``KeychainStorage/store(_:for:replaceDuplicates:)`` to place credentials into the keychain, and ``KeychainStorage/retrieveCredentials(withUsername:for:)`` to query them:
```swift
try keychainStorage.store(
    Credentials(username: "lukas", password: "isThisSecure?123"),
    for: .stanfordSUNet
)

// retrieval:
if let credentials = try keychainStorage.retrieveCredentials(withUsername: "lukas", for: .stanfordSUNet) {
    // ...
}
```

Credentials cannot be modified once they have been stored into the keychain, but you can use ``KeychainStorage/updateCredentials(withUsername:for:with:)`` which provides this functionality by replacing an existing credentials item with a new one.


You also can delete credentials entries from the keychain, using ``KeychainStorage/deleteCredentials(withUsername:for:)``:
```swift
try keychainStorage.deleteCredentials(
    withUsername: "lukas",
    for: .stanfordSUNet
)
```
This will delete all matching items from the keychain, for this combination of username and tag.


### Storing Keys

The `KeychainStorage` module also enables the creation, storage and management of cryptographic keys.

Analogously to ``CredentialsTag``, there exists a ``CryptographicKeyTag`` type which is used to define cryptographic key entries:

```swift
extension CryptographicKeyTag {
    static let databaseKey = Self("dbKey", storage: .secureEnclave, label: "Database Encryption")
}
```

You then can use the ``CryptographicKeyTag``s to store, retrieve, and delete keys:
```swift
let privateKey = try keychainStorage.createKey(for: .databaseKey)
let publicKey = try keychainStorage.retrievePublicKey(for: .databaseKey)
// ...
try keychainStorage.deleteKey(for: .databaseKey)
```

See ``KeychainStorage`` for more info.


## Topics

### Keychain Storage
- ``KeychainStorage``
