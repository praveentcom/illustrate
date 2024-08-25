import SwiftUI

struct ConnectionDetailsView: View {
    @Binding var isPresented: Bool
    @State var selectedConnection: Connection
    
    var body: some View {
        Form {
            Section("Details") {
                SectionKeyValueView(
                    key: "Logo",
                    value: selectedConnection.connectionName,
                    customValueView: Image("\(selectedConnection.connectionCode)_trimmed".lowercased()).resizable().scaledToFit().frame(height: 20)
                )
                SectionKeyValueView(key: "Name", value: selectedConnection.connectionName)
                SectionKeyValueView(key: "Description", value: selectedConnection.connectionDescription)
            }
            Section("Available Models") {
                ForEach(EnumSetType.allCases, id: \.self) { set in
                    let models = connectionModels.filter({ $0.modelSetType == set && $0.connectionId == selectedConnection.connectionId })
                    if !models.isEmpty {
                        SectionKeyValueView(
                            icon: iconForSetType(set),
                            key: labelForSetType(set),
                            value: models.map({ $0.modelName }).joined(separator: ", ")
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
                    isPresented = false
                }
            }
            
        }
        .frame(width: 480)
        .fixedSize()
#endif
    }
}
