import Foundation
import SwiftUI

struct DesktopView: View {
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var queueManager = QueueManager.shared
    @State private var selectedItem: EnumNavigationItem? = .dashboardWorkspace
    @State private var desktopNavigationPath = NavigationPath()

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
            .navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 240)
        } detail: {
            NavigationStack(path: $desktopNavigationPath) {
                if let currentItem = selectedItem {
                    viewForItem(currentItem)
                        .navigationDestination(for: EnumNavigationItem.self) { item in
                            viewForItem(item)
                        }
                } else {
                    Text("Select an item")
                }
            }
            .navigationSplitViewColumnWidth(min: 920, ideal: 920, max: .infinity)
        }
        .inspector(isPresented: .constant(true)) {
            QueueSidebarView(queueManager: queueManager)
                .inspectorColumnWidth(min: 320, ideal: 320, max: 320)
                .navigationTitle("Generation Queue")
                .interactiveDismissDisabled()
        }
        .environmentObject(navigationManager)
        .environmentObject(queueManager)
        .onChange(of: navigationManager.selectedNavigationItem) { _, newValue in
            if let newValue = newValue {
                desktopNavigationPath = NavigationPath()
                selectedItem = newValue
                navigationManager.selectedNavigationItem = nil
            }
        }
        .onChange(of: navigationManager.detailNavigationItem) { _, newValue in
            if let newValue = newValue {
                desktopNavigationPath.append(newValue)
                navigationManager.clearDetailNavigation()
            }
        }
    }
}
