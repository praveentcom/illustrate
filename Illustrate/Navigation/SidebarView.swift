import SwiftUI

struct SidebarView: View {
    var body: some View {
        List {
            NavigationSectionForImageGenerations()
            NavigationSectionForVideoGenerations()
            NavigationSectionForGenerationHistory()
            Section ("Settings") {
                NavigationLink(destination: ConnectionsView()) {
                    Label("Partner Connections", systemImage: "link")
                }
            }
        }
    }
}
