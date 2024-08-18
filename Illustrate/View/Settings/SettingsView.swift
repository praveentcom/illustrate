import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Integrations") {
                    NavigationLink(destination: ConnectionsView()) {
                        Label("Partner Connections", systemImage: "link")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
        }
    }
}
