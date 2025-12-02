import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var appVersionManager: AppVersionManager

    var body: some View {
        if horizontalSizeClass == .compact {
            MobileView()
                .sheet(isPresented: $appVersionManager.isTheFirstLaunch) {
                    WelcomeView(
                        action: { appVersionManager.isTheFirstLaunch = false }
                    )
                }
        } else {
            DesktopView()
                .sheet(isPresented: $appVersionManager.isTheFirstLaunch) {
                    WelcomeView(
                        action: { appVersionManager.isTheFirstLaunch = false }
                    )
                }
        }
    }
}
