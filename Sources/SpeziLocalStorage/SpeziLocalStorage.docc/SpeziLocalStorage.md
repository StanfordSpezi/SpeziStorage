# ``SpeziLocalStorage``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Store data encryped on-disk.

## Overview

The `LocalStorage` module enables encrypted on-disk storage of data in mobile applications.

The module defaults to storing data encrypted supported by the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.
The ``LocalStorageSetting`` enables configuring how data in the `LocalStorage` module can be stored and retrieved.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the `LocalStorage` module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

> Important: If you use the ``LocalStorage`` on the macOS platform, ensure to add the [`Keychain Access Groups` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/keychain-access-groups) to the enclosing Xcode project via *PROJECT_NAME > Signing&Capabilities > + Capability*. The array of keychain groups can be left empty, only the base entitlement is required.

```swift
import Spezi
import SpeziLocalStorage


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            LocalStorage()
            // ...
        }
    }
}
```


You can interact with the `LocalStorage` module from within SwiftUI views, either using the ``LocalStorageEntry`` property wrapper or by accessing the module directly (see below). 

Alternatively, it is common to use the `LocalStorage` module in other modules as a dependency: [Spezi Module dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module-dependency).


## Use the LocalStorage Module

You can use the `LocalStorage` module to store, update, retrieve, and delete element conforming to [`Codable`](https://developer.apple.com/documentation/swift/codable).


### Defining Storage Keys

`LocalStorage` uses unique ``LocalStorageKey``s to .

You define storage keys by placing a static non-computed properties of type ``LocalStorageKey`` into an extension on the ``LocalStorageKeys`` type:

```swift
struct Note: Codable, Equatable {
    let text: String
    let date: Date
}

extension LocalStorageKeys {
    // By default, storage keys are encoded using JSON and stored encrypted.
    static let note = LocalStorageKey<Note>("edu.stanford.spezi.note")
    
    // You can customize these aspects:
    static let plistNote = LocalStorageKey<Note>(
        "edu.stanford.spezi.note2",
        setting: .encryptedUsingSecureEnclave(),
        encoder: PropertyListEncoder(),
        decoder: PropertyListDecoder()
    )
}
```


### Storing and Loading Data

The `LocalStorage` module enables the storage and update of elements conforming to `Codable`.

```swift
let note = Note(text: "Spezi is awesome!", date: Date())

do {
    try localStorage.store(note, for: .note)
} catch {
    // Handle storage errors ...
}
```

See ``LocalStorage/store(_:encoder:storageKey:settings:)`` for more details.



### Reading Data

The `LocalStorage` module enables the retrieval of elements conforming to [`Codable`](https://developer.apple.com/documentation/swift/codable).

```swift
do {
    let storedNote = try localStorage.load(.note)
    // Do something with `storedNote`.
} catch {
    // Handle read errors ...
}
```

See ``LocalStorage/read(_:decoder:storageKey:settings:)`` for more details.


### Deleting Data

The `LocalStorage` module enables the deletion of a previously stored elements.

```swift
do {
    try localStorage.delete(.note)
} catch {
    // Handle delete errors ...
}
```

See ``LocalStorage/delete(_:)`` or ``LocalStorage/delete(storageKey:)`` for more details.

If you need to fully delete the entire local storage, use ``LocalStorage/deleteAll()``.


### SwiftUI

Use the ``LocalStorageEntry`` property wrapper to access individual entries of the `LocalStorage` within a SwiftUI view:
```swift
struct ExampleView: View {
    @LocalStorageEntry(.note)
    private var note
    
    var body: some View {
        // Use note within the view.
        // Assigning a new value to the property wrapper will automatically store it into the LocalStorage.
        // Furthermore, if some other part of your app stores a new value for the `.note` key,
        // the property wrapper will automatically update the view.
    }
}
```

Alternatively, you can also access the `LocalStorage` module directly:

```swift
struct ExampleStorageView: View {
    @Environment(LocalStorage.self) var localStorage

    var body: some View {
        // ...
    }
}
```



## Topics

### LocalStorage

- ``LocalStorage``
- ``LocalStorageKey``
- ``LocalStorageSetting``

