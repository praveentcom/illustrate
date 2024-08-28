import KeychainSwift
import SwiftUI

struct AddConnectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode

    @State var connectionId: UUID

    @State private var connection: Connection
    @State private var keyValue: String = ""

    init(connectionId: UUID) {
        self.connectionId = connectionId
        connection = connections.first { $0.connectionId == connectionId }!
    }

    var body: some View {
        Form {
            Section("Link Connection") {
                if connection.keyType == EnumConnectionKeyType.JSON {
                    TextField("JSON Key", text: $keyValue, prompt: Text(connection.keyPlaceholder), axis: .vertical)
                        .lineLimit(3 ... 8)
                } else {
                    TextField("API Key", text: $keyValue, prompt: Text(connection.keyPlaceholder))
                }
                Button("Save") {
                    addConnectionKey()
                }
                .disabled(keyValue.isEmpty)
            }

            Section("Instructions") {
                Image("\(connection.connectionCode)".lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Label("To connect \(connection.connectionName), you will need \(connection.keyType == EnumConnectionKeyType.JSON ? "a service account JSON credential" : "an API key"). If you don't have one, use the link below for assistance on how to get one.", systemImage: "1.circle.fill")
                Label("Once you link the key here, the same will be stored securely in your Apple Keychain. Illustrate will authenticate your requests with the connection provider via this key.", systemImage: "2.circle.fill")
                Label("To remove or revoke, simply delete from here or via the Keychain access application. Note that Illustrate never stores your keys outside your Keychain.", systemImage: "3.circle.fill")
                Label("Illustrate doesn't manage billing for these connections. Generation and other workflows might incur charges based on your usage. Refer to your connection provider for details.", systemImage: "4.circle.fill")
                Link("Visit connnection provider website for assistance", destination: URL(string: connection.connectionOnboardingUrl)!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(labelForItem(EnumNavigationItem.addConnection(connectionId: connectionId)))
    }

    private func addConnectionKey() {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        if keychain.get(connection.connectionId.uuidString) != nil {
            keychain.delete(connection.connectionId.uuidString)
        }

        if keychain.set(keyValue, forKey: connection.connectionId.uuidString) {
            let newKey = ConnectionKey(
                connectionId: connection.connectionId
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
