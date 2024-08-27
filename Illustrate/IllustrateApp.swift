import SwiftData
import SwiftUI

@main
struct IllustrateApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
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
