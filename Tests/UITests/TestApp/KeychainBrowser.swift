//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


@_spi(Internal) import SpeziKeychainStorage
import SwiftUI


struct KeychainBrowser: View { // swiftlint:disable:this file_types_order
    @Environment(KeychainStorage.self) private var keychain
    
    @State private var keys: [SecKey] = []
    @State private var genericCredentials: [Credentials] = []
    @State private var internetCredentials: [Credentials] = []
    
    var body: some View {
        Form {
            formActionSections
            formContentSections
        }
        .refreshable {
            updateKeys()
            updateCredentials()
        }
    }
    
    
    @ViewBuilder private var formActionSections: some View {
        Section {
            Button("Retrieve Keys") {
                updateKeys()
            }
            Button("Retrieve Credentials") {
                updateCredentials()
            }
        }
        Section {
            Button("Add Key Entry") {
                let tag1 = CryptographicKeyTag("edu.stanford.spezi.testKey1", storage: .secureEnclave, label: "Test Key 1")
                let tag2 = CryptographicKeyTag("edu.stanford.spezi.testKey2", storage: .keychain, label: "Test Key 2")
                _ = try? keychain.createKey(for: tag1)
                _ = try? keychain.createKey(for: tag2)
                updateKeys()
            }
            Button("Add Credentials Entry") {
                let tag1 = CredentialsTag.genericPassword(forService: "service_name")
                let tag2 = CredentialsTag.internetPassword(forServer: "stanford.edu")
                try? keychain.store(Credentials(username: "lukas", password: "1234"), for: tag1)
                try? keychain.store(Credentials(username: "lukas", password: "5678"), for: tag2)
                updateCredentials()
            }
        }
        Section {
            Button("Delete all Keys", role: .destructive) {
                try? keychain.deleteAllKeys(accessGroup: .any)
                updateKeys()
            }
            Button("Delete all Credentials (generic+internet)", role: .destructive) {
                try? keychain.deleteAllCredentials(accessGroup: .any)
                updateCredentials()
            }
        }
    }
    
    
    @ViewBuilder private var formContentSections: some View {
        Section("Generic Credentials") {
            ForEach(genericCredentials, id: \.self) { credentials in
                NavigationLink {
                    CredentialsDetailsView(credentials: credentials)
                } label: {
                    Text("\(credentials)")
                }
            }
        }
        Section("Internet Credentials") {
            ForEach(internetCredentials, id: \.self) { credentials in
                NavigationLink {
                    CredentialsDetailsView(credentials: credentials)
                } label: {
                    Text("\(credentials)")
                }
            }
        }
        Section("Keys") {
            ForEach(keys, id: \.self) { key in
                NavigationLink {
                    KeyDetailsView(key: key)
                } label: {
                    Text("\(key)")
                }
            }
        }
    }
    
    
    private func updateKeys() {
        keys = []
        for keyClass in [KeychainStorage.KeyClass.private, .public, .symmetric] {
            keys.append(contentsOf: (try? keychain.retrieveAllKeys(keyClass)) ?? [])
        }
    }
    
    private func updateCredentials() {
        genericCredentials = (try? keychain.retrieveAllGenericCredentials()) ?? []
        internetCredentials = (try? keychain.retrieveAllInternetCredentials()) ?? []
    }
}


private struct CredentialsDetailsView: View {
    let credentials: Credentials
    
    var body: some View {
        Form {
            LabeledContent("username", value: "\(credentials.username)")
            LabeledContent("password", value: "\(credentials.password)")
            LabeledContent("kind", value: "\(String(describing: credentials.kind))")
            LabeledContent("accessControl", value: "\(String(describing: credentials.accessControl))")
            LabeledContent("accessGroup", value: "\(credentials.accessGroup)")
            LabeledContent("accessible", value: "\(String(describing: credentials.accessible))")
            LabeledContent("creationDate", value: "\(String(describing: credentials.creationDate))")
            LabeledContent("modificationDate", value: "\(String(describing: credentials.modificationDate))")
            LabeledContent("description", value: "\(String(describing: credentials.description))")
            LabeledContent("comment", value: "\(String(describing: credentials.comment))")
            LabeledContent("creator", value: "\(String(describing: credentials.creator))")
            LabeledContent("type", value: "\(String(describing: credentials.type))")
            LabeledContent("label", value: "\(String(describing: credentials.label))")
            LabeledContent("isInvisible", value: "\(credentials.isInvisible)")
            LabeledContent("isNegative", value: "\(credentials.isNegative)")
            LabeledContent("synchronizable", value: "\(credentials.synchronizable)")
            
            if let credentials = credentials.asGenericCredentials {
                LabeledContent("service", value: "\(credentials.service)")
                LabeledContent("generic", value: "\(String(describing: credentials.generic))")
            } else if let credentials = credentials.asInternetCredentials {
                LabeledContent("securityDomain", value: "\(credentials.securityDomain)")
                LabeledContent("server", value: "\(credentials.server)")
                LabeledContent("protocol", value: "\(String(describing: credentials.protocol))")
                LabeledContent("authenticationType", value: "\(String(describing: credentials.authenticationType))")
                LabeledContent("port", value: "\(String(describing: credentials.port))")
                LabeledContent("path", value: "\(String(describing: credentials.path))")
            }
        }
    }
}


private struct KeyDetailsView: View {
    let key: SecKey
    
    var body: some View {
        Form {
            LabeledContent("publicKey", value: String(describing: key.publicKey))
            LabeledContent("applicationTag", value: String(describing: key.applicationTag))
            LabeledContent("applicationLabel", value: String(describing: key.applicationLabel))
            LabeledContent("label", value: String(describing: key.label))
            LabeledContent("keyType", value: String(describing: key.keyType))
            LabeledContent("keyClass", value: String(describing: key.keyClass))
            LabeledContent("isPublicKey", value: String(describing: key.isPublicKey))
            LabeledContent("isPrivateKey", value: String(describing: key.isPrivateKey))
            LabeledContent("accessGroup", value: String(describing: key.accessGroup))
            LabeledContent("sizeInBits", value: String(describing: key.sizeInBits))
            LabeledContent("accessControl", value: String(describing: key.accessControl))
            LabeledContent("accessible", value: String(describing: key.accessible))
            LabeledContent("isPermanent", value: String(describing: key.isPermanent))
            LabeledContent("effectiveKeySize", value: String(describing: key.effectiveKeySize))
            LabeledContent("canEncrypt", value: String(describing: key.canEncrypt))
            LabeledContent("canDecrypt", value: String(describing: key.canDecrypt))
            LabeledContent("canDerive", value: String(describing: key.canDerive))
            LabeledContent("canSign", value: String(describing: key.canSign))
            LabeledContent("canVerify", value: String(describing: key.canVerify))
            LabeledContent("canWrap", value: String(describing: key.canWrap))
            LabeledContent("canUnwrap", value: String(describing: key.canUnwrap))
            LabeledContent("synchronizable", value: String(describing: key.synchronizable))
            LabeledContent("tokenId", value: String(describing: key.tokenId))
        }
    }
}
