import AppTrackingTransparency
import KeychainSwift
import SwiftData
import SwiftUI

struct LinkedConnectionView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isLongPressActive = false
    @State private var showDeleteConfirmation = false

    let connection: Connection
    let connectionKey: ConnectionKey

    var body: some View {
        HStack {
            Label {
                Text("\(connection.connectionName)")
            } icon: {
                Image("\(connection.connectionCode)_square".lowercased())
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
            "Are you sure you want to disconnect \(connection.connectionName)?",
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

    func getLinkedConnections() -> [Connection] {
        return connections.filter { connection in
            connectionKeys.contains(where: { connection.connectionId == $0.connectionId })
        }
    }

    func getUnlinkedConnections() -> [Connection] {
        return connections.filter { connection in
            !connectionKeys.contains(where: { connection.connectionId == $0.connectionId })
        }
    }

    var body: some View {
        Form {
            if getLinkedConnections().count > 0 {
                Section("Linked Connections") {
                    ForEach(getLinkedConnections(), id: \.self) { connection in
                        if let connectionKey = connectionKeys.first(where: { $0.connectionId == connection.connectionId }) {
                            LinkedConnectionView(connection: connection, connectionKey: connectionKey)
                        }
                    }
                }
            }

            if getUnlinkedConnections().count > 0 {
                Section("Available Connections") {
                    ForEach(getUnlinkedConnections(), id: \.self) { connection in
                        NavigationLink(value: EnumNavigationItem.addConnection(connectionId: connection.connectionId)) {
                            Label {
                                Text("\(connection.connectionName)")
                            } icon: {
                                Image("\(connection.connectionCode)_square".lowercased())
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
        .navigationTitle(labelForItem(.settingsConnections))
    }
}
