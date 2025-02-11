//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
import Security


public enum KeychainItemAccessibility: Hashable, Sendable {
    /// The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
    case accessibleWhenPasscodeSetThisDeviceOnly
    
    /// The data in the keychain item can be accessed only while the device is unlocked by the user.
    case accessibleWhenUnlockedThisDeviceOnly
    
    /// The data in the keychain item can be accessed only while the device is unlocked by the user.
    case accessibleWhenUnlocked
    
    /// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
    case accessibleAfterFirstUnlockThisDeviceOnly
    
    /// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
    case accessibleAfterFirstUnlock
    
    
    public init?(_ value: CFString) {
        switch value {
        case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly:
            self = .accessibleWhenPasscodeSetThisDeviceOnly
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
            self = .accessibleWhenUnlockedThisDeviceOnly
        case kSecAttrAccessibleWhenUnlocked:
            self = .accessibleWhenUnlocked
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
            self = .accessibleAfterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlock:
            self = .accessibleAfterFirstUnlock
        default:
            return nil
        }
    }
    
    public var rawValue: CFString {
        switch self {
        case .accessibleWhenPasscodeSetThisDeviceOnly:
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .accessibleWhenUnlockedThisDeviceOnly:
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .accessibleWhenUnlocked:
            kSecAttrAccessibleWhenUnlocked
        case .accessibleAfterFirstUnlockThisDeviceOnly:
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .accessibleAfterFirstUnlock:
            kSecAttrAccessibleAfterFirstUnlock
        }
    }
}
