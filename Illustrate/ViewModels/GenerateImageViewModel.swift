import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

@MainActor
class GenerateImageViewModel: ObservableObject {
    private let modelContext: ModelContext?
    private let providerService: ProviderService
    private let keychain: KeychainSwift

    @Published var selectedProviderId: String = ""
    @Published var selectedModelId: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil

    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
    @Published var artDimensions: String = ""
    @Published var artQuality: EnumArtQuality = .HD
    @Published var artStyle: EnumArtStyle = .VIVID
    @Published var artVariant: EnumArtVariant = .NORMAL
    @Published var numberOfImages: Int = 1
    @Published var promptEnhanceOpted: Bool = false

    enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }
    
    private var focusedField: Field? = nil

    init(
        modelContext: ModelContext?,
        providerService: ProviderService = ProviderService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.modelContext = modelContext
        self.providerService = providerService
        self.keychain = keychain

        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

    func getSupportedModels() -> [ProviderModel] {
        guard !selectedProviderId.isEmpty else { return [] }

        return providerService.allModels.filter {
            $0.modelSetType == .GENERATE &&
            $0.providerId.uuidString == selectedProviderId &&
            $0.active
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
                $0.providerId == provider.providerId && $0.modelSetType == .GENERATE && $0.active
            }
        }
    }

    func initialize(providerKeys: [ProviderKey]) {
        guard !providerKeys.isEmpty && selectedModelId.isEmpty else { return }

        let supportedProviders = getSupportedProviders(providerKeys: providerKeys)

        if let firstSupportedProvider = supportedProviders.first,
           let key = providerKeys.first(where: { $0.providerId == firstSupportedProvider.providerId }) {
            selectedProviderId = key.providerId.uuidString

            let models = getSupportedModels()
            selectedModelId = models.first?.modelId.uuidString ?? ""

            if !selectedProviderId.isEmpty, !selectedModelId.isEmpty {
                artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
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
    }

    func generateImage(providerKeys: [ProviderKey]) async -> ImageSetResponse? {
        guard !isGenerating,
              let selectedModel = getSelectedModel() else {
            return nil
        }

        let providerSecret = keychain.get(selectedModel.providerId.uuidString)

        guard let secret = providerSecret else {
            await MainActor.run {
                isGenerating = false
            }
            return ImageSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Keychain record not found"
            )
        }

        guard let providerKey = providerKeys.first(where: {
            $0.providerId == selectedModel.providerId
        }) else {
            await MainActor.run {
                isGenerating = false
            }
            return ImageSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Provider key not found"
            )
        }

        await MainActor.run {
            isGenerating = true
        }

        do {
            let request = ImageGenerationRequest(
                modelId: selectedModel.modelId.uuidString,
                prompt: prompt,
                negativePrompt: negativePrompt,
                artVariant: artVariant,
                artQuality: artQuality,
                artStyle: artStyle,
                artDimensions: artDimensions,
                providerKey: providerKey,
                providerSecret: secret,
                numberOfImages: numberOfImages
            )

            let adapter = GenerateImageAdapter(
                imageGenerationRequest: request,
                modelContext: modelContext!
            )

            let response = await adapter.makeRequest()

            await MainActor.run {
                isGenerating = false
            }

            #if !os(macOS)
            try? await Task.sleep(nanoseconds: 500_000_000)
            #endif

            return response
        }
    }

    func handleGenerationResponse(response: ImageSetResponse?) {
        guard let response = response else { return }

        if response.status == .GENERATED && response.set?.id != nil {
            selectedSetId = response.set!.id
            isNavigationActive = true
        } else if response.status == .FAILED {
            errorState = ErrorState(
                message: response.errorMessage ?? "Something went wrong",
                isShowing: true
            )
        }
    }

    var canGenerate: Bool {
        return !isGenerating && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
