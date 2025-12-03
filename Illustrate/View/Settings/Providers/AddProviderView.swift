import KeychainSwift
import SwiftUI

struct AddProviderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode

    @State var providerId: UUID

    @State private var provider: Provider
    @State private var keyValue: String = ""

    init(providerId: UUID) {
        self.providerId = providerId
        provider = providers.first { $0.providerId == providerId }!
    }

    var body: some View {
        Form {
            Section("Link Provider") {
                if provider.keyType == EnumProviderKeyType.JSON {
                    TextField("JSON Key", text: $keyValue, prompt: Text(provider.keyPlaceholder), axis: .vertical)
                        .lineLimit(3 ... 8)
                } else {
                    TextField("API Key", text: $keyValue, prompt: Text(provider.keyPlaceholder))
                }
                Button("Save") {
                    addProviderKey()
                }
                .disabled(keyValue.isEmpty)
            }

            Section("Instructions") {
                Image("\(provider.providerCode)".lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Label("To connect \(provider.providerName), you will need \(provider.keyType == EnumProviderKeyType.JSON ? "a service account JSON credential" : "an API key"). If you don't have one, use the link below for assistance on how to get one.", systemImage: "1.circle.fill")
                Label("Once you link the key here, the same will be stored securely in your Apple Keychain. Illustrate will authenticate your requests with the provider via this key.", systemImage: "2.circle.fill")
                Label("To remove or revoke, simply delete from here or via the Keychain access application. Note that Illustrate never stores your keys outside your Keychain.", systemImage: "3.circle.fill")
                Label("Illustrate doesn't manage billing for these providers. Generation and other workflows might incur charges based on your usage. Refer to your provider for details.", systemImage: "4.circle.fill")
                Button("Get \(provider.keyType == EnumProviderKeyType.JSON ? "JSON credential" : "API key")") {
                    guard let url = URL(string: provider.providerOnboardingUrl) else { return }
                    #if os(macOS)
                    NSWorkspace.shared.open(url)
                    #else
                    UIApplication.shared.open(url)
                    #endif
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(labelForItem(EnumNavigationItem.addProvider(providerId: providerId)))
    }

    private func addProviderKey() {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        if keychain.get(provider.providerId.uuidString) != nil {
            keychain.delete(provider.providerId.uuidString)
        }

        if keychain.set(keyValue, forKey: provider.providerId.uuidString) {
            let newKey = ProviderKey(
                providerId: provider.providerId
            )

            modelContext.insert(newKey)
            try? modelContext.save()
        } else {
            print("Failed to save key.")

            if keychain.lastResultCode != noErr {
                print("Keychain error: \(keychain.lastResultCode)")
            }
        }

        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
