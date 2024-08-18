import SwiftUI

struct AddConnectionView: View {
    @Binding var isPresented: Bool
    @State var partnerKeys: [PartnerKey]

    var body: some View {
        NavigationStack {
            ConnectionFormView(isPresented: $isPresented, partnerKeys: partnerKeys)
        }
    }
}
