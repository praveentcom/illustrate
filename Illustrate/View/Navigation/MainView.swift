import OnboardingUI
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.appVersionManager) private var appVersionManager

    var body: some View {
        @Bindable var appVersionManager = appVersionManager

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
