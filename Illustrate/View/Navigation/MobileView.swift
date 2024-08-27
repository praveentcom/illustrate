import Foundation
import SwiftUI

struct MobileView: View {
    @State private var homeNavigationPath = NavigationPath()
    @State private var generationsNavigationPath = NavigationPath()
    @State private var historyNavigationPath = NavigationPath()
    @State private var settingsNavigationPath = NavigationPath()

    var body: some View {
        TabView {
            NavigationStack(path: $homeNavigationPath) {
                WorkspaceView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("Workspace", systemImage: "house")
            }

            NavigationStack(path: $generationsNavigationPath) {
                GenerateView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("Generate", systemImage: "paintbrush")
            }

            NavigationStack(path: $historyNavigationPath) {
                HistoryView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("History", systemImage: "photo.on.rectangle.angled")
            }

            NavigationStack(path: $settingsNavigationPath) {
                SettingsView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
