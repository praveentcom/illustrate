import SwiftUI
import SwiftData

struct ManageStorageView: View {
    @Environment (\.modelContext) private var modelContext
    @State private var showConfirmation = false
    
    var generationsCount: Int {
        let descriptor = FetchDescriptor<Generation>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        return count
    }
    
    func clearStorage() {
        do {
            try modelContext.delete(model: Generation.self)
            try modelContext.delete(model: ImageSet.self)
            
            try modelContext.save()
            
            deleteAllICloudDocuments()
        } catch {
            print("Failed to clear storage.")
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack (spacing: 8) {
                    Image(systemName: "lock.icloud")
                        .font(.title)
                    Text("You have \(generationsCount) generations synced to your iCloud account.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("This action cannot be reversed as your data is not stored anywhere else apart from your iCloud account. Proceed with caution.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Button("Clear Storage", role: .destructive, action: {
                        DispatchQueue.main.async {showConfirmation = true }
                    })
                    .buttonStyle(.borderedProminent)
                    .padding(.all, 8)
                }
                .padding(.all, 12)
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Clear all data?"),
                message: Text("This cannot be reversed as your data is not stored anywhere else apart from your iCloud account. Are you sure you want to continue?"),
                primaryButton: .destructive(Text("Delete"), action: clearStorage),
                secondaryButton: .cancel()
            )
        }
        .navigationTitle(labelForItem(.settingsManageStorage))
    }
}
