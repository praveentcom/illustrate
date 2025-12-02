import SwiftData
import SwiftUI

struct ConnectionDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var connectionKeys: [ConnectionKey]
    @Binding var isPresented: Bool
    @State var selectedConnection: Connection

    var isConnected: Bool {
        connectionKeys.contains { $0.connectionId == selectedConnection.connectionId }
    }

    var body: some View {
        Form {
            Section("Details") {
                SectionKeyValueView(
                    key: "Provider Logo",
                    value: selectedConnection.connectionName,
                    customValueView: Image("\(selectedConnection.connectionCode)_trimmed".lowercased()).resizable().scaledToFit().frame(height: 20)
                )
                SectionKeyValueView(key: "Provider Name", value: selectedConnection.connectionName)
                SectionKeyValueView(key: "Description", value: selectedConnection.connectionDescription)
            }
            Section("Available Models") {
                ForEach(EnumSetType.allCases, id: \.self) { set in
                    let models = ConnectionService.shared.models(for: set).filter { $0.connectionId == selectedConnection.connectionId }
                    if !models.isEmpty {
                        SectionKeyValueView(
                            icon: iconForSetType(set),
                            key: labelForSetType(set),
                            value: models.map { $0.modelName }.joined(separator: "\n")
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        DispatchQueue.main.async {
                            isPresented = false
                        }
                    }
                }
                if !isConnected {
                    ToolbarItem(placement: .confirmationAction) {
                        NavigationLink(value: EnumNavigationItem.addConnection(connectionId: selectedConnection.connectionId)) {
                            Text("Connect")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            DispatchQueue.main.async {
                                isPresented = false
                            }
                        })
                    }
                }
            }
            .frame(width: 480)
            .fixedSize()
        #else
            .toolbar {
                if !isConnected {
                    ToolbarItem(placement: .confirmationAction) {
                        NavigationLink(value: EnumNavigationItem.addConnection(connectionId: selectedConnection.connectionId)) {
                            Text("Connect")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            DispatchQueue.main.async {
                                isPresented = false
                            }
                        })
                    }
                }
            }
        #endif
    }
}
