import SwiftData
import SwiftUI
import Combine

final class AppVersionManager: ObservableObject {
    @Published var isTheFirstLaunch: Bool = true

    init() {
        checkFirstLaunch()
    }

    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        isTheFirstLaunch = !hasLaunchedBefore

        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

@main
struct IllustrateApp: App {
    @StateObject private var appVersionManager = AppVersionManager()
    @StateObject private var connectionService = ConnectionService.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appVersionManager)
                .environmentObject(connectionService)
                .environment(\.connectionService, connectionService)
                .modelContainer(
                    for: [
                        Connection.self,
                        ConnectionKey.self,
                        ConnectionModel.self,
                        Generation.self,
                        ImageSet.self,
                    ]
                )
            #if os(macOS)
                .frame(
                    minWidth: 1200,
                    maxWidth: .infinity,
                    minHeight: 760,
                    maxHeight: .infinity
                )
            #endif
        }
    }
}
