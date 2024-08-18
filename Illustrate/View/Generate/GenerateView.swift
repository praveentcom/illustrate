import SwiftUI

struct GenerateView: View {
    var body: some View {
        NavigationStack {
            Form {
                NavigationSectionForImageGenerations()
                NavigationSectionForVideoGenerations()
            }
            .formStyle(.grouped)
            .navigationTitle("Generate")
        }
    }
}
