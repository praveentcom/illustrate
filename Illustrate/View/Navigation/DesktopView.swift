import Foundation
import SwiftUI

struct DesktopView: View {
    @StateObject private var navigationManager = NavigationManager()
    @EnvironmentObject var queueService: GenerationQueueService
    @State private var selectedItem: EnumNavigationItem? = .dashboardWorkspace
    @State private var desktopNavigationPath = NavigationPath()
    @State private var showQueueSidebar: Bool = true

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                ForEach(EnumNavigationSection.allCases, id: \.self) { section in
                    Section(section.rawValue) {
                        ForEach(sectionItems(section: section), id: \.self) { item in
                            NavigationLink(value: item) {
                                Label(labelForItem(item), systemImage: iconForItem(item))
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 240)
        } detail: {
            HStack(spacing: 0) {
                NavigationStack(path: $desktopNavigationPath) {
                    if let selectedItem = navigationManager.selectedNavigationItem ?? selectedItem {
                        viewForItem(selectedItem)
                            .navigationDestination(for: EnumNavigationItem.self) { item in
                                viewForItem(item)
                            }
                    } else {
                        Text("Select an item")
                    }
                }
                #if os(macOS)
                .frame(minWidth: 800)
                #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            showQueueSidebar.toggle()
                        }) {
                            Label("Queue", systemImage: showQueueSidebar ? "sidebar.right" : "sidebar.right")
                                .help("Toggle Queue Sidebar")
                        }
                    }
                }
                
                if showQueueSidebar {
                    Divider()
                    QueueSidebarView()
                }
            }
        }
        .environmentObject(navigationManager)
        .onChange(of: navigationManager.selectedNavigationItem) { _, newValue in
            if let newValue = newValue {
                selectedItem = newValue
            }
        }
    }
}
