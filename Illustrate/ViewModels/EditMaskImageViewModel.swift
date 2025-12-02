import Foundation
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
class EditMaskImageViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext?
    private let connectionService: ConnectionService
    private let keychain: KeychainSwift

    // MARK: - Published Properties
    @Published var selectedConnectionId: String = ""
    @Published var selectedModelId: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil

    // MARK: - Form Properties
    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
    @Published var artDimensions: String = ""
    @Published var artQuality: EnumArtQuality = .HD
    @Published var artStyle: EnumArtStyle = .VIVID
    @Published var artVariant: EnumArtVariant = .NORMAL
    @Published var numberOfImages: Int = 1
    @Published var promptEnhanceOpted: Bool = false

    // MARK: - Photo Properties
    @Published var selectedImageItem: PhotosPickerItem?
    @Published var selectedImage: PlatformImage?
    @Published var colorPalette: [String] = []
    @Published var isPhotoPickerOpen: Bool = false
    @Published var isCropSheetOpen: Bool = false

    // MARK: - Mask Properties
    @Published var maskPath = Path()
    @Published var canvasSize = CGSize.zero

    // MARK: - Focus State
    private enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }
    
    private var focusedField: Field? = nil

    // MARK: - Initialization
    init(
        modelContext: ModelContext?,
        connectionService: ConnectionService = ConnectionService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.modelContext = modelContext
        self.connectionService = connectionService
        self.keychain = keychain

        // Configure keychain
        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

    // MARK: - Connection and Model Management
    func getSupportedModels() -> [ConnectionModel] {
        guard !selectedConnectionId.isEmpty else { return [] }

        return connectionService.models(for: .EDIT_MASK).filter {
            $0.connectionId.uuidString == selectedConnectionId
        }
    }

    func getSelectedModel() -> ConnectionModel? {
        guard !selectedModelId.isEmpty else { return nil }
        return connectionService.model(by: selectedModelId)
    }

    func getSupportedConnections(connectionKeys: [ConnectionKey]) -> [Connection] {
        return connections.filter { connection in
            connectionKeys.contains { $0.connectionId == connection.connectionId } &&
            connectionService.allModels.contains {
                $0.connectionId == connection.connectionId && $0.modelSetType == .EDIT_MASK && $0.active
            }
        }
    }

    // MARK: - Initialization Logic
    func initialize(connectionKeys: [ConnectionKey]) {
        guard !connectionKeys.isEmpty && selectedModelId.isEmpty else { return }

        let supportedConnections = getSupportedConnections(connectionKeys: connectionKeys)

        if let firstSupportedConnection = supportedConnections.first,
           let key = connectionKeys.first(where: { $0.connectionId == firstSupportedConnection.connectionId }) {
            selectedConnectionId = key.connectionId.uuidString

            let models = getSupportedModels()
            selectedModelId = models.first?.modelId.uuidString ?? ""

            if !selectedConnectionId.isEmpty, !selectedModelId.isEmpty {
                artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
            }
        }
    }

    // MARK: - Dimension Management
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

    // MARK: - Image Processing
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

    // MARK: - Mask Management
    func clearMask() {
        maskPath = Path()
    }

    func updateMaskPath(_ path: Path) {
        maskPath = path
    }

    // MARK: - Image Generation with Mask
    func generateImage(connectionKeys: [ConnectionKey]) async -> ImageSetResponse? {
        guard !isGenerating,
              let selectedModel = getSelectedModel(),
              let selectedImage = selectedImage else {
            return nil
        }

        // Get connection secret from keychain
        let connectionSecret = keychain.get(selectedModel.connectionId.uuidString)

        guard let secret = connectionSecret else {
            await MainActor.run {
                isGenerating = false
            }
            return ImageSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Keychain record not found"
            )
        }

        // Find connection key
        guard let connectionKey = connectionKeys.first(where: {
            $0.connectionId == selectedModel.connectionId
        }) else {
            await MainActor.run {
                isGenerating = false
            }
            return ImageSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Connection key not found"
            )
        }

        // Generate mask image
        let clientMask = exportPathToImage(
            path: maskPath,
            size: canvasSize
        )

        await MainActor.run {
            isGenerating = true
        }

        do {
            let request = ImageGenerationRequest(
                modelId: selectedModel.modelId.uuidString,
                prompt: prompt,
                negativePrompt: negativePrompt,
                artDimensions: artDimensions,
                clientImage: selectedImage.toBase64PNG(),
                clientMask: clientMask?.toBase64PNG(),
                connectionKey: connectionKey,
                connectionSecret: secret
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

        } catch {
            await MainActor.run {
                isGenerating = false
                errorState = ErrorState(
                    message: "Failed to generate image: \(error.localizedDescription)",
                    isShowing: true
                )
            }
            return nil
        }
    }

    // MARK: - Generation Handler
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

    // MARK: - Validation
    var canGenerate: Bool {
        return !isGenerating && selectedImage != nil && !maskPath.isEmpty
    }

    var hasConnection: Bool {
        return !selectedModelId.isEmpty
    }

    var hasMask: Bool {
        return !maskPath.isEmpty
    }

    // MARK: - Cleanup
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
        prompt = ""
        negativePrompt = ""
    }
}
