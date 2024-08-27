import Foundation
import SwiftUI

struct DesktopView: View {
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
            .frame(minWidth: 240)
        } detail: {
            NavigationStack(path: $desktopNavigationPath) {
                if let selectedItem = selectedItem {
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
        }
    }
}
