import Foundation
import SwiftUI

struct PendingProviderView: View {
    var setType: EnumSetType

    var providersWithSetTypeSupport: [Provider] {
        return providers.filter { provider in
            ProviderService.shared.allModels.contains { $0.providerId == provider.providerId && $0.modelSetType == setType && $0.active }
        }
    }

    let columns: [GridItem] = {
        #if os(macOS)
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
        #else
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
        #endif
    }()

    var body: some View {
        Form {
            Section("Provider pending") {
                VStack(spacing: 8) {
                    Text("No providers that support \(labelForSetType(setType)) are linked yet.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("You can connect via the providers page.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 12)
                .frame(maxWidth: .infinity)
                NavigationLink(value: EnumNavigationItem.settingsProviders) {
                    Label("Manage Providers", systemImage: "link")
                }
            }
            Section("Supported Providers") {
                VStack(alignment: .leading) {
                    if providersWithSetTypeSupport.isEmpty {
                        Text("No providers that support \(labelForSetType(setType)) are available yet.")
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(providersWithSetTypeSupport, id: \.self) { item in
                                WorkspaceProviderShortcut(item: item, setType: setType, showModels: true)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
