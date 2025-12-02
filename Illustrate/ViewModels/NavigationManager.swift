import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedNavigationItem: EnumNavigationItem? = nil

    func navigate(to item: EnumNavigationItem) {
        selectedNavigationItem = item
    }

    func navigateToGeneration(setId: UUID) {
        navigate(to: .generationImage(setId: setId))
    }
}