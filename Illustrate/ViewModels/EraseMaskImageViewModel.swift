import Foundation
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
class EraseMaskImageViewModel: ObservableObject {
    private let modelContext: ModelContext?
    private let providerService: ProviderService
    private let keychain: KeychainSwift

    @Published var selectedProviderId: String = ""
    @Published var selectedModelId: String = ""
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil
    @Published var showQueuedToast: Bool = false

    @Published var artDimensions: String = ""
    @Published var artQuality: EnumArtQuality = .HD
    @Published var artStyle: EnumArtStyle = .VIVID
    @Published var artVariant: EnumArtVariant = .NORMAL
    @Published var numberOfImages: Int = 1
    @Published var promptEnhanceOpted: Bool = false

    @Published var selectedImageItem: PhotosPickerItem?
    @Published var selectedImage: PlatformImage?
    @Published var colorPalette: [String] = []
    @Published var isPhotoPickerOpen: Bool = false
    @Published var isCropSheetOpen: Bool = false

    @Published var maskPath = Path()
    @Published var canvasSize = CGSize.zero

    private enum Field: Int, CaseIterable {
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

        return providerService.models(for: .EDIT_MASK_ERASE).filter {
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
                $0.providerId == provider.providerId && $0.modelSetType == .EDIT_MASK_ERASE && $0.active
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

    func updateDimensions(dimension: String) {
        guard artDimensions != dimension else { return }

        artDimensions = dimension
        selectedImage = nil
        colorPalette = []
        maskPath = Path()
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

    func processSelectedImage(loaded: Data) {
        #if os(macOS)
        selectedImage = NSImage(data: loaded)
        #else
        selectedImage = UIImage(data: loaded)
        #endif

        if let selectedImage = selectedImage {
            colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
            isCropSheetOpen = true
        }
    }

    func handleImageCropping(image: PlatformImage) {
        let targetSize = CGSize(
            width: getAspectRatio(dimension: artDimensions).actualWidth,
            height: getAspectRatio(dimension: artDimensions).actualHeight
        )

        selectedImage = image.resizeImage(targetSize: targetSize)
        canvasSize = targetSize

        if let selectedImage = selectedImage {
            colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
        }

        isCropSheetOpen = false
    }

    func cancelImageCropping() {
        selectedImage = nil
        colorPalette = []
        maskPath = Path()
        canvasSize = .zero
        isCropSheetOpen = false
    }

    func clearMask() {
        maskPath = Path()
    }

    func updateMaskPath(_ path: Path) {
        maskPath = path
    }

    func submitToQueue(providerKeys: [ProviderKey], queueManager: QueueManager) {
        guard let selectedModel = getSelectedModel(),
              let selectedImage = selectedImage else {
            errorState = ErrorState(
                message: "No image or model selected",
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

        let clientMask = exportPathToImage(
            path: maskPath,
            size: canvasSize
        )

        let request = ImageGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: "",
            negativePrompt: "",
            artDimensions: artDimensions,
            clientImage: selectedImage.toBase64PNG(),
            clientMask: clientMask?.toBase64PNG(),
            providerKey: providerKey,
            providerSecret: providerSecret
        )

        _ = queueManager.submitImageGeneration(
            request: request,
            modelContext: modelContext!
        )

        showQueuedToast = true
    }

    var canGenerate: Bool {
        return selectedImage != nil && !maskPath.isEmpty
    }

    var hasProvider: Bool {
        return !selectedModelId.isEmpty
    }

    var hasMask: Bool {
        return !maskPath.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }

    func resetAll() {
        selectedImage = nil
        colorPalette = []
        maskPath = Path()
        canvasSize = .zero
    }
}
