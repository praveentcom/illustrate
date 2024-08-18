import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            TabView {
                GenerateView()
                    .tabItem {
                        Label("Generate", systemImage: "photo")
                    }
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "photo.on.rectangle")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        } else {
            NavigationSplitView {
                SidebarView()
                    .frame(minWidth: 240)
            } detail: {
                VStack {
                    NavigationStack {
                        GenerateImageView()
                    }
                }
                #if os(macOS)
                    .frame(minWidth: 800)
                #endif
            }
        }
    }
}
