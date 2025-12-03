import AppTrackingTransparency
import KeychainSwift
import SwiftData
import SwiftUI

struct LinkedProviderView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isLongPressActive = false
    @State private var showDeleteConfirmation = false

    let provider: Provider
    let providerKey: ProviderKey

    var body: some View {
        HStack {
            Label {
                Text("\(provider.providerName)")
            } icon: {
                Image("\(provider.providerCode)_square".lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Spacer()
            Image(systemName: "minus.circle")
                .font(.headline)
                .foregroundStyle(.red)
                .onTapGesture {
                    DispatchQueue.main.async {
                        showDeleteConfirmation = true
                    }
                }
        }
        .confirmationDialog(
            "Are you sure you want to remove \(provider.providerName)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                deleteProviderKey(providerKey)
            }

            Button("Cancel", role: .cancel) {
                DispatchQueue.main.async {
                    showDeleteConfirmation = false
                }
            }
        }
    }

    private func deleteProviderKey(_ providerKey: ProviderKey) {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        if keychain.get(providerKey.providerId.uuidString) != nil {
            keychain.delete(providerKey.providerId.uuidString)
        }

        modelContext.delete(providerKey)

        try? modelContext.save()
    }
}

struct ProvidersView: View {
    @Query(sort: \ProviderKey.createdAt, order: .reverse) private var providerKeys: [ProviderKey]
    @AppStorage("hasRequestedTrackingAuthorization") private var hasRequestedTrackingAuthorization = false

    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            hasRequestedTrackingAuthorization = true

            switch status {
            case .authorized:
                print("Tracking authorized")
            case .denied:
                print("Tracking denied")
            case .notDetermined:
                print("Tracking not determined")
            case .restricted:
                print("Tracking restricted")
            @unknown default:
                print("Unknown tracking status")
            }
        }
    }

    func getLinkedProviders() -> [Provider] {
        return providers.filter { provider in
            providerKeys.contains(where: { provider.providerId == $0.providerId })
        }
    }

    func getUnlinkedProviders() -> [Provider] {
        return providers.filter { provider in
            !providerKeys.contains(where: { provider.providerId == $0.providerId })
        }
    }

    var body: some View {
        Form {
            if getLinkedProviders().count > 0 {
                Section("Linked Providers") {
                    ForEach(getLinkedProviders(), id: \.self) { provider in
                        if let providerKey = providerKeys.first(where: { $0.providerId == provider.providerId }) {
                            LinkedProviderView(provider: provider, providerKey: providerKey)
                        }
                    }
                }
            }

            if getUnlinkedProviders().count > 0 {
                Section("Available Providers") {
                    ForEach(getUnlinkedProviders(), id: \.self) { provider in
                        NavigationLink(value: EnumNavigationItem.addProvider(providerId: provider.providerId)) {
                            Label {
                                Text("\(provider.providerName)")
                            } icon: {
                                Image("\(provider.providerCode)_square".lowercased())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if !hasRequestedTrackingAuthorization {
                requestTrackingAuthorization()
            }
        }
        .navigationTitle(labelForItem(.settingsProviders))
    }
}
