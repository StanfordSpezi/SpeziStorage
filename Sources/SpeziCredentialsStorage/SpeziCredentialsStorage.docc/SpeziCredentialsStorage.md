# ``SpeziCredentialsStorage``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Securely store small chunks of data, such as credentials and keys.


## Overview

The `CredentialsStorage` module allows for the encrypted storage of small chunks of sensitive user data, such as usernames and passwords for internet services,
using Apple's [Keychain](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets). 

Credentials can be stored in the Secure Enclave (if available) or the Keychain. Credentials stored in the Keychain can be made synchronizable between different instances of user devices.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

> Important: If you use the ``CredentialsStorage`` on the macOS platform, ensure to add the [`Keychain Access Groups` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/keychain-access-groups) to the enclosing Xcode project via *PROJECT_NAME > Signing&Capabilities > + Capability*. The array of keychain groups can be left empty, only the base entitlement is required.

You can configure the ``CredentialsStorage`` module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

```swift
import Spezi
import SpeziCredentialsStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            CredentialsStorage()
            // ...
        }
    }
}
```

You can then access the `CredentialsStorage` class in any SwiftUI view.

```swift
struct ExampleStorageView: View {
    @Environment(CredentialsStorage.self) var credentialsStorage

    var body: some View {
        // ...
    }
}
```

Alternatively, it is common to use the `CredentialsStorage` module in other modules as a dependency: [Spezi Module dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module-dependency).


## Use the CredentialsStorage Module

You can use the `CredentialsStorage` module to store, update, retrieve, and delete credentials and keys. 


### Storing Credentials

The `CredentialsStorage` module enables the storage of credentials in the Keychain.

Teo kinds of credentials can be stored:
1. internet passwords, i.e., credentials that are associated with some specific hostname;
2. generic passwords, which are just a username-password pair and not associated with a hostname.

You use the ``CredentialsStorageKey`` type to define how individual entries are persisted in the `CredentialsStorage`.

Credentials cannot be mutated once they are stored in the database, but they can be updated by replacing an old entry with a new one.

```swift
extension CredentialsStorageKey {
    static let accountLogin = CredentialsStorageKey(
        kind: .internetPassword(server: "stanford.edu"),
        storageScope: .keychainSynchronizable()
    )
}


// storing credentials:
try credentialsStorage.store(
    Credentials(username: "lukas", password: "isThisSecure?123"),
    for: .accountLogin
)

// loading credentials:
if let credentials = try credentialsStorage.retrieveCredentials(withUsername: "lukas", forKey: .accountLogin) {
    // ...
}

// updating credentials:
try credentialsStorage.updateCredentials(
    forUsername: "lukas",
    key: .accountLogin,
    with: Credentials(username: "lukas", password: "newAndBetterPassword")
)
```

See also:
- ``CredentialsStorage/store(_:for:removeDuplicate:)``
- ``CredentialsStorage/retrieveCredentials(withUsername:forKey:)``
- ``CredentialsStorage/retrieveAllCredentials(for:)``
- ``CredentialsStorage/retrieveAllCredentials(ofType:)``
- ``CredentialsStorage/updateCredentials(forUsername:key:with:removeDuplicate:)``
- ``CredentialsStorage/deleteCredentials(withUsername:for:)``



### Handling Keys

Similar to ``Credentials`` instances, you can also use the `CredentialsStorage` module to interact with keys.

- ``CredentialsStorage/createKey(for:size:storageScope:)``
- ``CredentialsStorage/retrievePublicKey(for:)``
- ``CredentialsStorage/retrievePrivateKey(for:)``
- ``CredentialsStorage/deleteKeys(for:)``


## Topics

### Credentials Storage
- ``CredentialsStorage``
- ``CredentialsStorageKey``
- ``KeyTag``
