import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(EnumNavigationSection.Settings.rawValue) {
                List(sectionItems(section: EnumNavigationSection.Settings), id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(labelForItem(item), systemImage: iconForItem(item))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(EnumNavigationSection.Settings.rawValue)
    }
}
