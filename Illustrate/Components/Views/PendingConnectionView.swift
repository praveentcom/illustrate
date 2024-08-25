import SwiftUI
import Foundation

struct PendingConnectionView: View {
    var setType: EnumSetType
    
    var connectionsWithSetTypeSupport: [Connection] {
        return connections.filter { connection in
            connectionModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == setType }
        }
    }
    
    let columns: [GridItem] = {
        #if os(macOS)
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        #else
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 1)
        #endif
    }()
    
    var body: some View {
        Form {
            Section("Connection pending") {
                VStack (spacing: 8) {
                    Text("No connections that support \(labelForSetType(setType)) are linked yet.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("You can connect via the connections page.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 12)
                .frame(maxWidth: .infinity)
                NavigationLink(value: EnumNavigationItem.settingsConnections) {
                    Label("Manage Connections", systemImage: "link")
                }
            }
            Section("Supported Connections") {
                VStack (alignment: .leading) {
                    if (connectionsWithSetTypeSupport.isEmpty) {
                        Text("No connections that support \(labelForSetType(setType)) are available yet.")
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(connectionsWithSetTypeSupport, id: \.self) { item in
                                WorkspaceConnectionShortcut(item: item)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
