import SwiftUI

struct HistoryView: View {
    var body: some View {
        Form {
            Section(EnumNavigationSection.History.rawValue) {
                List(sectionItems(section: EnumNavigationSection.History), id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(labelForItem(item), systemImage: iconForItem(item))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(EnumNavigationSection.History.rawValue)
    }
}
