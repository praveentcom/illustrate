import SwiftUI
import Foundation

struct PendingConnectionView: View {
    var setType: EnumSetType
    
    var body: some View {
        Form {
            Section ("Connection pending") {
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
        }
        .formStyle(.grouped)

    }
}
