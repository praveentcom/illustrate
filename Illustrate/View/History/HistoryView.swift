import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Form {
                NavigationSectionForGenerationHistory()
                NavigationSectionForUsageMetrics()
            }
            .formStyle(.grouped)
            .navigationTitle("History")
        }
    }
}
