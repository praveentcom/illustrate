import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            MobileView()
        } else {
            DesktopView()
        }
    }
}
