import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedNavigationItem: EnumNavigationItem? = nil
    @Published var detailNavigationItem: EnumNavigationItem? = nil

    func navigate(to item: EnumNavigationItem) {
        selectedNavigationItem = item
    }

    func navigateToGeneration(setId: UUID) {
        navigate(to: .generationImage(setId: setId))
    }
    
    func pushDetail(_ item: EnumNavigationItem) {
        detailNavigationItem = item
    }
    
    func clearDetailNavigation() {
        detailNavigationItem = nil
    }
}