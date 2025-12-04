import SwiftData
import SwiftUI

struct ProviderDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navigationManager: NavigationManager
    @Query private var providerKeys: [ProviderKey]
    @Binding var isPresented: Bool
    @State var selectedProvider: Provider

    var isConnected: Bool {
        providerKeys.contains { $0.providerId == selectedProvider.providerId }
    }

    private func navigateToAddProvider() {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigationManager.pushDetail(.addProvider(providerId: selectedProvider.providerId))
        }
    }

    var body: some View {
        Form {
            Section("Details") {
                SectionKeyValueView(
                    key: "Provider Logo",
                    value: selectedProvider.providerName,
                    customValueView: Image("\(selectedProvider.providerCode)_trimmed".lowercased()).resizable().scaledToFit().frame(height: 20)
                )
                SectionKeyValueView(key: "Provider Name", value: selectedProvider.providerName)
                SectionKeyValueView(key: "Description", value: selectedProvider.providerDescription)
            }
            Section("Available Models") {
                ForEach(EnumSetType.allCases, id: \.self) { set in
                    let models = ProviderService.shared.models(for: set).filter { $0.providerId == selectedProvider.providerId }
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
                        Button("Connect") {
                            navigateToAddProvider()
                        }
                    }
                }
            }
            .frame(width: 480)
            .fixedSize()
        #else
            .toolbar {
                if !isConnected {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Connect") {
                            navigateToAddProvider()
                        }
                    }
                }
            }
        #endif
    }
}
