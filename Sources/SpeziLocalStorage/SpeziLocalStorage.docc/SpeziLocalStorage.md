# ``SpeziLocalStorage``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Store data encryped on-disk.

## Overview

The ``LocalStorage`` module enables the on-disk storage of data in mobile applications.

The ``LocalStorage`` module defaults to storing data encrypted supported by the [`SecureStorage`](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/spezisecurestorage) module.
The ``LocalStorageSetting`` enables configuring how data in the ``LocalStorage`` module can be stored and retrieved.


## Setup

You need to add the Spezi Storage Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the ``LocalStorage`` module in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate).

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

You can then use the ``LocalStorage`` class in any SwiftUI view.

```swift
struct ExampleStorageView: View {
    @EnvironmentObject var localStorage: LocalStorage
    
    
    var body: some View {
        // ...
    }
}
```

Alternatively, it is common to use the ``LocalStorage`` module in other modules as a dependency: [Spezi component dependencies](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/component#Dependencies).


## Use the LocalStorage Module

You can use the ``LocalStorage`` module to store, update, retrieve, and delete element conforming to [`Codable`](https://developer.apple.com/documentation/swift/codable). 


### Storing & Update Data

The ``LocalStorage`` module enables the storage and update of elements conforming to [`Codable`](https://developer.apple.com/documentation/swift/codable).

```swift
struct Note: Codable, Equatable {
    let text: String
    let date: Date
}

let note = Note(text: "Spezi is awesome!", date: Date())

do {
    try await localStorage.store(note)
} catch {
    // Handle storage errors ...
}
```

See ``LocalStorage/store(_:storageKey:settings:)`` for more details.



### Read Data

The ``LocalStorage`` module enables the retrieval of elements conforming to [`Codable`](https://developer.apple.com/documentation/swift/codable).

```swift
do {
    let storedNote: Note = try await localStorage.read()
    // Do something with `storedNote`.
} catch {
    // Handle read errors ...
}
```

See ``LocalStorage/read(_:storageKey:settings:)`` for more details.


### Deleting Element

The ``LocalStorage`` module enables the deletion of a previously stored elements.

```swift
do {
    try await localStorage.delete(storageKey: "MyNote")
} catch {
    // Handle delete errors ...
}
```

See ``LocalStorage/delete(_:)`` or ``LocalStorage/delete(storageKey:)`` for more details.


## Topics

### LocalStorage

- ``LocalStorage``
- ``LocalStorageSetting``
- ``LocalStorage/store(_:storageKey:settings:)``
- ``LocalStorage/read(_:storageKey:settings:)``
- ``LocalStorage/delete(storageKey:)``
- ``LocalStorage/delete(_:)``

