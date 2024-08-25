import SwiftUI

struct GenerateView: View {
    var body: some View {
        Form {
            Section(EnumNavigationSection.ImageGenerations.rawValue) {
                List(sectionItems(section: EnumNavigationSection.ImageGenerations), id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(labelForItem(item), systemImage: iconForItem(item))
                    }
                }
            }
            Section(EnumNavigationSection.VideoGenerations.rawValue) {
                List(sectionItems(section: EnumNavigationSection.VideoGenerations), id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(labelForItem(item), systemImage: iconForItem(item))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Generate")
    }
}
