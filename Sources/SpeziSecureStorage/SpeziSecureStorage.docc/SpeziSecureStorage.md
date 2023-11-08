# ``SpeziSecureStorage``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Securely store small chunks of data, such as credentials and keys.


## Overview

The ``SecureStorage`` module allows for the encrypted storage of small chunks of sensitive user data, such as usernames and passwords for internet services, using Apple's [Keychain documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets). 

Credentials can be stored in the Secure Enclave (if available) or the Keychain. Credentials stored in the Keychain can be made synchronizable between different instances of user devices.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the ``SecureStorage`` module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

```swift
import Spezi
import SpeziSecureStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            SecureStorage()
            // ...
        }
    }
}
```

You can then use the ``SecureStorage`` class in any SwiftUI view.

```swift
struct ExampleStorageView: View {
    @Environment(SecureStorage.self) var secureStorage
    
    
    var body: some View {
        // ...
    }
}
```

Alternatively, it is common to use the ``SecureStorage`` module in other modules as a dependency: [Spezi component dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/component#Dependencies).


## Use the SecureStorage Module

You can use the ``SecureStorage`` module to store, update, retrieve, and delete credentials and keys. 


### Storing Credentials

The ``SecureStorage`` module enables the storage of credentials in the Keychain.

```swift
do {
    let serverCredentials = Credentials(
        username: "user",
        password: "password"
    )
    try secureStorage.store(
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

See ``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)`` for more details.



### Retrieving Credentials

The ``SecureStorage`` module enables the retrieval of existing credentials stored in the Keychain.

```swift
guard let serverCredentials = secureStorage.retrieveCredentials("user", server: "stanford.edu") else {
    // Handle errors here.
}

// Use the credentials
```

See ``SecureStorage/retrieveCredentials(_:server:accessGroup:)`` or ``SecureStorage/retrieveAllCredentials(forServer:accessGroup:)`` for more details.


### Updating Credentials

The ``SecureStorage`` module enables the update of existing credentials found in the Keychain.

```swift
do {
    let newCredentials = Credentials(
        username: "user",
        password: "newPassword"
    )
    try secureStorage.updateCredentials(
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

See ``SecureStorage/updateCredentials(_:server:newCredentials:newServer:removeDuplicate:storageScope:)`` for more details.


### Deleting Credentials

The ``SecureStorage`` module enables the deletion of a previously stored set of credentials.

```swift
do {
    try secureStorage.deleteCredentials(
        "user",
        server: "spezi.stanford.edu"
    )
} catch {
    // Handle deletion error here.
    // ...
}
```

See ``SecureStorage/deleteCredentials(_:server:accessGroup:)`` or ``SecureStorage/deleteAllCredentials(itemTypes:accessGroup:)`` for more details.


### Handeling Keys

Similiar to ``Credentials`` instances, you can also use the ``SecureStorage`` module to interact with keys.

- ``SecureStorage/createKey(_:size:storageScope:)``
- ``SecureStorage/retrievePublicKey(forTag:)``
- ``SecureStorage/retrievePrivateKey(forTag:)``
- ``SecureStorage/deleteKeys(forTag:)``


## Topics

### Secure Storage
- ``SecureStorage``
- ``SecureStorageError``
- ``SecureStorageScope``

### Handling Credentials 

- ``Credentials``
- ``SecureStorage/store(credentials:server:removeDuplicate:storageScope:)``
- ``SecureStorage/retrieveCredentials(_:server:accessGroup:)``
- ``SecureStorage/retrieveAllCredentials(forServer:accessGroup:)``
- ``SecureStorage/updateCredentials(_:server:newCredentials:newServer:removeDuplicate:storageScope:)``
- ``SecureStorage/deleteCredentials(_:server:accessGroup:)``
- ``SecureStorage/deleteAllCredentials(itemTypes:accessGroup:)``
- ``SecureStorageItemTypes``

### Handling Keys 

- ``SecureStorage/createKey(_:size:storageScope:)``
- ``SecureStorage/retrievePublicKey(forTag:)``
- ``SecureStorage/retrievePrivateKey(forTag:)``
- ``SecureStorage/deleteKeys(forTag:)``
