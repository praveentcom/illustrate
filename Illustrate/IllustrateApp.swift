//
//  illustrateApp.swift
//  illustrate
//
//  Created by Praveen Thirumurugan on 12/08/24.
//

import SwiftUI
import SwiftData

@main
struct IllustrateApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: [Partner.self, PartnerKey.self, PartnerModel.self, Generation.self, ImageSet.self])
            #if os(macOS)
                .frame(minWidth: 1200, maxWidth: .infinity, minHeight: 720, maxHeight: .infinity)
            #endif
        }
    }
}
