import AppTrackingTransparency
import KeychainSwift
import SwiftData
import SwiftUI

struct ConnectedConnectionCell: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLongPressActive = false
    @State private var showDeleteConfirmation = false

    let connectionName: String
    let connectionKey: ConnectionKey

    var body: some View {
        HStack {
            Text(connectionName)
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
            "Are you sure you want to disconnect \(connectionName)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                deleteConnectionKey(connectionKey)
            }

            Button("Cancel", role: .cancel) {
                DispatchQueue.main.async {
                    showDeleteConfirmation = false
                }
            }
        }
    }

    private func deleteConnectionKey(_ connectionKey: ConnectionKey) {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        if keychain.get(connectionKey.connectionId.uuidString) != nil {
            keychain.delete(connectionKey.connectionId.uuidString)
        }

        modelContext.delete(connectionKey)

        try? modelContext.save()
    }
}

struct ConnectionsView: View {
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]
    @AppStorage("hasRequestedTrackingAuthorization") private var hasRequestedTrackingAuthorization = false

    @State private var showingAddConnection = false

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

    var body: some View {
        Form {
            Section("Enabled Connections") {
                if connectionKeys.isEmpty {
                    Text("Tap the 'Add Connection' button to add one.")
                } else {
                    ForEach(connectionKeys) { connectionKey in
                        ConnectedConnectionCell(
                            connectionName: connections.first(where: { $0.connectionId == connectionKey.connectionId })?.connectionName ?? "",
                            connectionKey: connectionKey
                        )
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
        .toolbar {
            Button("+ Connect") {
                DispatchQueue.main.async {
                    showingAddConnection = true
                }
            }
        }
        .sheet(isPresented: $showingAddConnection) {
            AddConnectionView(isPresented: $showingAddConnection, connectionKeys: connectionKeys)
        }
        .navigationTitle(labelForItem(.settingsConnections))
    }
}
