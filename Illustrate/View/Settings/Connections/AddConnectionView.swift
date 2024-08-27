import KeychainSwift
import SwiftUI

struct AddConnectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State var connectionKeys: [ConnectionKey]
    @State private var selectedConnection: Connection?
    @State private var keyValue: String = ""

    private var availableConnections: [Connection] {
        connections.filter { connection in
            !connectionKeys.contains { connectionKey in
                connectionKey.connectionId == connection.connectionId
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if availableConnections.isEmpty {
                    Text("All connections have been added.")
                } else {
                    if selectedConnection != nil {
                        Picker("Connection", selection: $selectedConnection) {
                            ForEach(availableConnections) { connection in
                                Text(connection.connectionName).tag(connection as Connection?)
                            }
                        }
                        if selectedConnection!.keyType == EnumConnectionKeyType.JSON {
                            TextField("JSON Key", text: $keyValue, prompt: Text(selectedConnection!.keyPlaceholder), axis: .vertical)
                                .lineLimit(3 ... 8)
                        } else {
                            TextField("API Key", text: $keyValue, prompt: Text(selectedConnection!.keyPlaceholder))
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .onAppear {
                DispatchQueue.main.async {
                    selectedConnection = selectedConnection ?? availableConnections.first
                }
            }
            .navigationTitle("Add Connection")
            .toolbar {
                toolbarContent
            }
            #if os(macOS)
            .frame(width: 480)
            .fixedSize()
            #endif
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    DispatchQueue.main.async {
                        isPresented = false
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    addConnectionKey()
                }
                .disabled(selectedConnection == nil || keyValue.isEmpty)
            }
        #else
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    DispatchQueue.main.async {
                        isPresented = false
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    addConnectionKey()
                }
                .disabled(selectedConnection == nil || keyValue.isEmpty)
            }
        #endif
    }

    private func addConnectionKey() {
        guard let selectedConnection else { return }

        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        if keychain.get(selectedConnection.connectionId.uuidString) != nil {
            keychain.delete(selectedConnection.connectionId.uuidString)
        }

        if keychain.set(keyValue, forKey: selectedConnection.connectionId.uuidString) {
            let newKey = ConnectionKey(
                connectionId: selectedConnection.connectionId,
                creditCurrency: selectedConnection.creditCurrency
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
            isPresented = false
        }
    }
}
