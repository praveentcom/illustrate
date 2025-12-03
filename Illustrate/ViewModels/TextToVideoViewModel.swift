import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

@MainActor
class TextToVideoViewModel: ObservableObject {
    private let providerService: ProviderService
    private let keychain: KeychainSwift

    @Published var selectedProviderId: String = ""
    @Published var selectedModelId: String = ""
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil
    @Published var showQueuedToast: Bool = false

    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
    @Published var artDimensions: String = ""
    @Published var selectedResolution: String = ""
    @Published var selectedFPS: Int = 24
    @Published var durationSeconds: Int = 8
    @Published var generateAudio: Bool = true

    var focusedField: Field? = nil

    enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }

    init(
        providerService: ProviderService = ProviderService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.providerService = providerService
        self.keychain = keychain

        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

    func getSupportedModels(providerKeys: [ProviderKey]) -> [ProviderModel] {
        guard !selectedProviderId.isEmpty else { return [] }

        return providerService.models(for: .VIDEO_TEXT).filter {
            $0.providerId.uuidString == selectedProviderId
        }
    }

    func getSelectedModel() -> ProviderModel? {
        guard !selectedModelId.isEmpty else { return nil }
        return providerService.model(by: selectedModelId)
    }

    func getSupportedProviders(providerKeys: [ProviderKey]) -> [Provider] {
        return providers.filter { provider in
            providerKeys.contains { $0.providerId == provider.providerId } &&
            providerService.allModels.contains {
                $0.providerId == provider.providerId && $0.modelSetType == .VIDEO_TEXT && $0.active
            }
        }
    }
    
    func getSupportedDurations() -> [Int] {
        guard let model = getSelectedModel() else { return [8] }
        let durations = model.modelSupportedParams.supportedDurations
        return durations.isEmpty ? [8] : durations
    }
    
    func getValidatedDuration() -> Int {
        let supported = getSupportedDurations().sorted()
        if supported.contains(durationSeconds) {
            return durationSeconds
        }

        let lower = supported.filter { $0 <= durationSeconds }
        return lower.last ?? supported.first ?? durationSeconds
    }
    
    func getSupportedResolutions() -> [String] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedResolutions
    }
    
    var hasResolutionOptions: Bool {
        return !getSupportedResolutions().isEmpty
    }
    
    func getSupportedFPS() -> [Int] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedFPS
    }
    
    var hasFPSOptions: Bool {
        return !getSupportedFPS().isEmpty
    }
    
    var supportsAudio: Bool {
        return getSelectedModel()?.modelSupportedParams.supportsAudio ?? false
    }

    func initialize(providerKeys: [ProviderKey]) {
        guard !providerKeys.isEmpty && selectedModelId.isEmpty else { return }

        let supportedProviders = getSupportedProviders(providerKeys: providerKeys)

        if let firstSupportedProvider = supportedProviders.first,
           let key = providerKeys.first(where: { $0.providerId == firstSupportedProvider.providerId }) {
            selectedProviderId = key.providerId.uuidString

            let models = getSupportedModels(providerKeys: providerKeys)
            selectedModelId = models.first?.modelId.uuidString ?? ""

            if !selectedProviderId.isEmpty, !selectedModelId.isEmpty {
                artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
                selectedResolution = getSupportedResolutions().last ?? ""
                selectedFPS = getSupportedFPS().first ?? 24
                durationSeconds = getSupportedDurations().last ?? 8
            }
        }
    }

    func validateAndSetDimensions() {
        let selectedModel = getSelectedModel()
        let supportedDimensions = selectedModel?.modelSupportedParams.dimensions ?? []

        if artDimensions.isEmpty {
            artDimensions = supportedDimensions.first ?? ""
        } else if !supportedDimensions.contains(artDimensions) {
            artDimensions = supportedDimensions.first ?? ""
        }
        
        let supportedResolutions = getSupportedResolutions()
        if selectedResolution.isEmpty || !supportedResolutions.contains(selectedResolution) {
            selectedResolution = supportedResolutions.last ?? ""
        }
        
        let supportedFPS = getSupportedFPS()
        if !supportedFPS.contains(selectedFPS) {
            selectedFPS = supportedFPS.first ?? 24
        }
        
        let supportedDurations = getSupportedDurations()
        if !supportedDurations.contains(durationSeconds) {
            durationSeconds = supportedDurations.last ?? 8
        }
    }

    func submitToQueue(providerKeys: [ProviderKey], queueManager: QueueManager, modelContext: ModelContext) {
        guard let selectedModel = getSelectedModel() else {
            errorState = ErrorState(
                message: "No model selected",
                isShowing: true
            )
            return
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorState = ErrorState(
                message: "Prompt is required to generate a video",
                isShowing: true
            )
            return
        }

        guard let providerSecret = keychain.get(selectedModel.providerId.uuidString) else {
            errorState = ErrorState(
                message: "Keychain record not found",
                isShowing: true
            )
            return
        }

        guard let providerKey = providerKeys.first(where: {
            $0.providerId == selectedModel.providerId
        }) else {
            errorState = ErrorState(
                message: "Provider key not found",
                isShowing: true
            )
            return
        }
        
        let resolution: String
        if hasResolutionOptions {
            resolution = selectedResolution
        } else {
            resolution = artDimensions.contains("1080") || artDimensions.contains("1920") ? "1080p" : "720p"
        }

        let request = VideoGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            artDimensions: artDimensions,
            providerKey: providerKey,
            providerSecret: providerSecret,
            durationSeconds: getValidatedDuration(),
            resolution: resolution,
            fps: hasFPSOptions ? selectedFPS : nil,
            generateAudio: supportsAudio ? generateAudio : nil
        )

        _ = queueManager.submitVideoGeneration(
            request: request,
            modelContext: modelContext
        )

        showQueuedToast = true
    }

    var canGenerate: Bool {
        return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedModelId.isEmpty
    }

    var hasProvider: Bool {
        return !selectedModelId.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}
