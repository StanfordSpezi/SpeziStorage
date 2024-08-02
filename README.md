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

The Spezi Storage framework provides two Modules that enable on-disk storage of information.
The  [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module can be used to store information that does not need to be encrypted.
Credentials, keys, and other sensitive information that needs to be encrypted may be stored by using the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> [!IMPORTANT]
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

> [!IMPORTANT]
> If you use SpeziStorage on the macOS platform, ensure to add the [`Keychain Access Groups` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/keychain-access-groups) to the enclosing Xcode project via *PROJECT_NAME > Signing&Capabilities > + Capability*. The array of keychain groups can be left empty, only the base entitlement is required.

You can configure the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) or [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

```swift
import Spezi
import SpeziLocalStorage
import SpeziSecureStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LocalStorage()
            SecureStorage()
            // ...
        }
    }
}
```

You can then use the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) or [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) class in any SwiftUI view.

```swift
struct ExampleStorageView: View {
    @Environment(LocalStorage.self) var secureStorage
    @Environment(SecureStorage.self) var secureStorage
    
    
    var body: some View {
        // ...
    }
}
```

Alternatively, it is common to use the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) or [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module in other modules as a dependency: [Spezi Module dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module-dependency).


## Local Storage

The [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module enables the on-disk storage of data in mobile applications.

The [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module defaults to storing data encrypted supported by the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.
The [`LocalStorageSetting`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstoragesetting) enables configuring how data in the [`LocalStorage`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage) module can be stored and retrieved.

- Store or update new elements: [`store(_:encoder:storageKey:settings:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage/store(_:encoder:storagekey:settings:))
- Retrieve existing elements: [`read(_:decoder:storageKey:settings:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage/read(_:decoder:storagekey:settings:))
- Delete existing elements: [`delete(_:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezilocalstorage/localstorage/delete(_:))


## Secure Storage

The [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module allows for the encrypted storage of small chunks of sensitive user data, such as usernames and passwords for internet services, using Apple's [Keychain documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/using_the_keychain_to_manage_user_secrets). 

Credentials can be stored in the Secure Enclave (if available) or the Keychain. Credentials stored in the Keychain can be made synchronizable between different instances of user devices.

### Handling Credentials

Use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module to store a set of [`Credentials`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/credentials) instances in the Keychain associated with a server that is synchronizable between different devices.

- Store new credentials: [`store(credentials:server:removeDuplicate:storageScope:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/store(credentials:server:removeduplicate:storagescope:))
- Retrieve existing credentials: [`retrieveCredentials(_:server:accessGroup:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/retrievecredentials(_:server:accessgroup:))
- Retrieve all matching existing credentials: [`retrieveAllCredentials(forServer:accessGroup:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/retrieveallcredentials(forserver:accessgroup:))
- Update existing credentials: [`updateCredentials(_:server:newCredentials:newServer:removeDuplicate:storageScope:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/updatecredentials(_:server:newcredentials:newserver:removeduplicate:storagescope:))
- Delete existing credentials: [`deleteCredentials(_:server:accessGroup:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/deletecredentials(_:server:accessgroup:))
- Delete all matching existing credentials: [`deleteAllCredentials(itemTypes:accessGroup:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/deleteallcredentials(itemtypes:accessgroup:))


### Handling Keys

Similar to [`Credentials`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/credentials) instances, you can also use the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module to interact with keys.

- Create new keys: [`createKey(_:size:storageScope:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/createkey(_:size:storagescope:))
- Retrieve existing public keys: [`retrievePublicKey(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/retrievepublickey(fortag:))
- Retrieve existing private keys: [`retrievePrivateKey(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/retrieveprivatekey(fortag:))
- Delete existing keys: [`deleteKeys(forTag:)`](https://swiftpackageindex.com/stanfordspezi/spezistorage/documentation/spezisecurestorage/securestorage/deletekeys(fortag:))

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation).


## The Spezi Template Application

The [Spezi Template Application](https://github.com/StanfordSpezi/SpeziTemplateApplication) provides a great starting point and example using the Spezi Storage module.


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziStorage/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
