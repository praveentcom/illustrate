import SwiftUI
import SwiftData

struct ConnectedPartnerCell: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLongPressActive = false
    @State private var showDeleteConfirmation = false
    
    let partnerName: String
    let partnerKey: PartnerKey
    
    var body: some View {
        HStack {
            Text(partnerName)
            Spacer()
            Image(systemName: "minus.circle")
                .font(.headline)
                .foregroundStyle(.red)
                .onTapGesture {
                    showDeleteConfirmation = true
                }
        }
        .confirmationDialog(
            "Are you sure you want to disconnect \(partnerName)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                deletePartnerKey(partnerKey)
            }
            
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
        }
    }
    
    private func deletePartnerKey(_ partnerKey: PartnerKey) {
        modelContext.delete(partnerKey)
        try? modelContext.save()
    }
}

struct ConnectionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PartnerKey.createdAt, order: .reverse) private var partnerKeys: [PartnerKey]
    @State private var showingAddConnection = false
    
    var body: some View {
        Form {
            Section("Enabled Connections") {
                if (partnerKeys.isEmpty) {
                    Text("Tap the 'Add Connection' button to add one.")
                } else {
                    ForEach(partnerKeys) { partnerKey in
                        ConnectedPartnerCell(
                            partnerName: partners.first(where: { $0.partnerId == partnerKey.partnerId })?.partnerName ?? "",
                            partnerKey: partnerKey
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
#if os(macOS)
            Button(
                "Add Connection"
            ) {
                showingAddConnection = true
            }

#else
            Button(
                "Add"
            ) {
                showingAddConnection = true
            }
#endif
        }
        .sheet(isPresented: $showingAddConnection) {
            AddConnectionView(isPresented: $showingAddConnection, partnerKeys: partnerKeys)
        }
        .navigationTitle("Partner Connections")
    }
}
