import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Form {
                NavigationSectionForGenerationHistory()
            }
            .formStyle(.grouped)
            .navigationTitle("History")
        }
    }
}
