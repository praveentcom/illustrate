import Foundation
import SwiftUI

struct MobileView: View {
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var queueManager = QueueManager.shared
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
                Label("Generate", systemImage: "sparkles")
            }

            MobileQueueView()
                .tabItem {
                    Label("Queue", systemImage: "list.bullet.rectangle")
                }
                .badge(queueManager.totalCount > 0 ? queueManager.totalCount : 0)

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
        .environmentObject(navigationManager)
        .environmentObject(queueManager)
    }
}
