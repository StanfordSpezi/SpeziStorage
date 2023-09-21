<!--

This source file is part of the Stanford Spezi open-source project.

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
  
-->

# Spezi Storage

[![Build and Test](https://github.com/StanfordSpezi/SpeziStorage/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziStorage/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziStorage/branch/main/graph/badge.svg?token=XJ8IJuc0hj)](https://codecov.io/gh/StanfordSpezi/SpeziStorage)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7804028.svg)](https://doi.org/10.5281/zenodo.7804028)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStorage%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziStorage%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage)

The Spezi Storage module consists of two sub-modules that enable on-disk storage of information, the  [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module can be used to store information that does not need to be encrypted. Credentials, keys, and other sensitive information that needs to be encrypted may be stored by using the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.

# Spezi Local Storage

## Overview

The [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module enables the on-disk storage of data in mobile applications. The [`LocalStorageSetting`](https://swiftpackageindex.com/stanfordspezi/spezistorage/0.4.2/documentation/spezilocalstorage/localstoragesetting) enables configuring how data in the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module can be stored and retrieved.

The data stored can optionally be encrypted by importing the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.

## Setup

> [!IMPORTANT]  
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/setup) setup the core Spezi infrastructure.

You can configure the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

```swift
import Spezi
import LocalStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LocalStorage()
        }
    }
}
```

You can then use the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) class in any SwiftUI view.

```swift
struct ExampleLocalStorageView: View {
    @EnvironmentObject var localStorage: LocalStorage
    
    
    var body: some View {
        // ...
    }
}
```

Alternatively it is common to use the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module in other modules as a dependency.

## Example

### Storing data

```swift
struct Note: Codable, Equatable {
    let text: String
    let date: Date
}

let note = Note(text: "Spezi is awesome!", date: Date())

do {
    try await localStorage.store(
        note,
        storageKey: "MyNote",
        settings: .unencrypted()
    )
} catch {
    // Handle storage error here
    // ...
}

```

### Reading stored data

```swift
do {
    let storedNote: Note = try await localStorage.read(
        storageKey: "MyNote", 
        settings: .unencrypted()
    )
    // Do something with `storedNote`.
} catch {
    // Handle read error.
    // ...
}
```

### Deleting stored data

```swift
do {
    try await localStorage.delete(storageKey: "MyNote")
} catch {
    // Handle delete error.
    // ...
}
```

# Spezi Secure Storage

## Overview

The [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module allows for the encrypted storage of small chunks of sensitive user data, such as usernames and passwords for internet services, using Apple's [Keychain documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets). 

Credentials can be stored in the Secure Enclave (if available) or the Keychain. Credentials stored in the Keychain can be made synchronizable between different instances of user devices.


## Setup

> [!IMPORTANT]  
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/setup) setup the core Spezi infrastructure.

You can configure the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) component in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).
```swift
import Spezi
import SecureStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            SecureStorage()
        }
    }
}
```

You can then use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) class in any SwiftUI view.

```swift
struct ExampleSecureStorageView: View {
    @EnvironmentObject var secureStorage: SecureStorage
    
    
    var body: some View {
        // ...
    }
}
```

Alternatively it is common to use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module in other modules as a dependency:

## Example

### Storing Credentials

Use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module to store a set of [`Credentials`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/credentials) instances in the Keychain associated with a server that is synchronizable between different devices.

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

### Retrieving Credentials

```swift
if let serverCredentials = secureStorage.retrieveCredentials(
    "user", 
    server: "stanford.edu"
) {
    // Use credentials here.
    // ...
}
```

### Updating Credentials

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

### Deleting Credentials

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

### Handling Keys

Similiar to [`Credentials`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/credentials) instances, you can also use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module to interact with keys.

- [`createKey(_:size:storageScope:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/createkey(_:size:storagescope:))
- [`retrievePrivateKey(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/createkey(_:size:storagescope:))
- [`retrievePublicKey(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/retrievepublickey(fortag:))
- [`deleteKeys(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/deletekeys(fortag:))

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation).


## The Spezi Template Application

The [Spezi Template Application](https://github.com/StanfordSpezi/SpeziTemplateApplication) provides a great starting point and example using the Spezi Storage module.


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziStorage/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
