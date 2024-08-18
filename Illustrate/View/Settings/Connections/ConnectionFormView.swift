import SwiftUI

struct ConnectionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State var partnerKeys: [PartnerKey]
    @State private var selectedPartner: Partner?
    @State private var keyValue: String = ""
    
    private var availablePartners: [Partner] {
        partners.filter { partner in
            !partnerKeys.contains { partnerKey in
                partnerKey.partnerId == partner.partnerId
            }
        }
    }
    
    var body: some View {
        if availablePartners.isEmpty {
            VStack {
                Text("No partners available")
            }
            .padding()
            .navigationTitle("Connect Partner")
            .toolbar {
                toolbarContent
            }
        } else {
            Form {
                if selectedPartner != nil {
                    Picker("Partner", selection: $selectedPartner) {
                        ForEach(availablePartners) { partner in
                            Text(partner.partnerName).tag(partner as Partner?)
                        }
                    }
                }
                if let selectedPartner, selectedPartner.keyType == EnumPartnerKeyType.JSON {
                    TextField("JSON Key", text: $keyValue, prompt: Text(selectedPartner.keyStructure), axis: .vertical)
                        .lineLimit(3...8)
                } else {
                    TextField("API Key", text: $keyValue, prompt: Text(selectedPartner?.keyStructure ?? ""))
                }
            }
            .formStyle(.grouped)
            .onAppear {
                selectedPartner = selectedPartner ?? availablePartners.first
            }
            .navigationTitle("Connect Partner")
            .toolbar {
                toolbarContent
            }
            #if os(macOS)
            .frame(width: 480)
            .fixedSize()
            #endif
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                isPresented = false
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                addPartnerKey()
            }
            .disabled(selectedPartner == nil || keyValue.isEmpty)
        }
        #else
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                isPresented = false
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                addPartnerKey()
            }
            .disabled(selectedPartner == nil || keyValue.isEmpty)
        }
        #endif
    }
    
    private func addPartnerKey() {
        guard let selectedPartner else { return }
        
        let newKey = PartnerKey(
            partnerId: selectedPartner.partnerId,
            value: keyValue,
            creditCurrency: selectedPartner.creditCurrency
        )
        
        modelContext.insert(newKey)
        try? modelContext.save()
        isPresented = false
    }
}
