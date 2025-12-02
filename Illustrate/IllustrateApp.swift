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
    @StateObject private var queueService = GenerationQueueService.shared

    var body: some Scene {
        WindowGroup {
            ContentWrapperView()
                .environmentObject(appVersionManager)
                .environmentObject(connectionService)
                .environmentObject(queueService)
                .environment(\.connectionService, connectionService)
                .modelContainer(
                    for: [
                        Connection.self,
                        ConnectionKey.self,
                        ConnectionModel.self,
                        Generation.self,
                        ImageSet.self,
                        QueueItem.self,
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

struct ContentWrapperView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var queueService: GenerationQueueService
    
    var body: some View {
        MainView()
            .onAppear {
                queueService.setModelContext(modelContext)
            }
    }
}
