import SwiftUI
import Combine

class iCloudViewModel: ObservableObject {
    @Published var isICloudAvailable = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkICloudAvailability()
        observeICloudChanges()
    }
    
    func checkICloudAvailability() {
        isICloudAvailable = FileManager.default.ubiquityIdentityToken != nil
    }
    
    func observeICloudChanges() {
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { _ in
                self.checkICloudAvailability()
            }
            .store(in: &cancellables)
    }
}
