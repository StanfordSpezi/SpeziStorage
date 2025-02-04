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

You can then use the `CredentialsStorage` class in any SwiftUI view.

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

```swift
do {
    let serverCredentials = Credentials(
        username: "user",
        password: "password"
    )
    try credentialsStorage.store(
        credentials: serverCredentials,
        server: "stanford.edu",
        storageScope: .keychainSynchronizable
    )

    // ...
} catch {
    // Handle creation error here.
    // ...
}
```

See ``CredentialsStorage/store(credentials:server:removeDuplicate:storageScope:)`` for more details.



### Retrieving Credentials

The `CredentialsStorage` module enables the retrieval of existing credentials stored in the Keychain.

```swift
guard let serverCredentials = credentialsStorage.retrieveCredentials("user", server: "stanford.edu") else {
    // Handle errors here.
}

// Use the credentials
```

See ``CredentialsStorage/retrieveCredentials(_:server:accessGroup:)`` or ``CredentialsStorage/retrieveAllCredentials(forServer:accessGroup:)`` for more details.


### Updating Credentials

The `CredentialsStorage` module enables the update of existing credentials found in the Keychain.

```swift
do {
    let newCredentials = Credentials(
        username: "user",
        password: "newPassword"
    )
    try credentialsStorage.updateCredentials(
        "user",
        server: "stanford.edu",
        newCredentials: newCredentials,
        newServer: "spezi.stanford.edu"
    )
} catch {
    // Handle update error here.
    // ...
}
```

See ``CredentialsStorage/updateCredentials(_:server:newCredentials:newServer:removeDuplicate:storageScope:)`` for more details.


### Deleting Credentials

The `CredentialsStorage` module enables the deletion of a previously stored set of credentials.

```swift
do {
    try credentialsStorage.deleteCredentials(
        "user",
        server: "spezi.stanford.edu"
    )
} catch {
    // Handle deletion error here.
    // ...
}
```

See ``CredentialsStorage/deleteCredentials(_:server:accessGroup:)`` or ``CredentialsStorage/deleteAllCredentials(itemTypes:accessGroup:)`` for more details.


### Handling Keys

Similar to ``Credentials`` instances, you can also use the `CredentialsStorage` module to interact with keys.

- ``CredentialsStorage/createKey(_:size:storageScope:)``
- ``CredentialsStorage/retrievePublicKey(forTag:)``
- ``CredentialsStorage/retrievePrivateKey(forTag:)``
- ``CredentialsStorage/deleteKeys(forTag:)``


## Topics

### Credentials Storage
- ``CredentialsStorage``
- ``CredentialsStorageError``
- ``CredentialsStorageScope``
- ``CredentialsStorageItemTypes``
