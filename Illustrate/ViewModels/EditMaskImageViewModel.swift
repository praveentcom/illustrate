import Foundation
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
class EditMaskImageViewModel: ObservableObject {
    private let modelContext: ModelContext?
    private let connectionService: ConnectionService
    private let keychain: KeychainSwift

    @Published var selectedConnectionId: String = ""
    @Published var selectedModelId: String = ""
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil
    @Published var showQueuedToast: Bool = false

    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
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
        connectionService: ConnectionService = ConnectionService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.modelContext = modelContext
        self.connectionService = connectionService
        self.keychain = keychain

        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

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

    func submitToQueue(connectionKeys: [ConnectionKey], queueManager: QueueManager) {
        guard let selectedModel = getSelectedModel(),
              let selectedImage = selectedImage else {
            errorState = ErrorState(
                message: "No image or model selected",
                isShowing: true
            )
            return
        }

        guard let connectionSecret = keychain.get(selectedModel.connectionId.uuidString) else {
            errorState = ErrorState(
                message: "Keychain record not found",
                isShowing: true
            )
            return
        }

        guard let connectionKey = connectionKeys.first(where: {
            $0.connectionId == selectedModel.connectionId
        }) else {
            errorState = ErrorState(
                message: "Connection key not found",
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
            prompt: prompt,
            negativePrompt: negativePrompt,
            artDimensions: artDimensions,
            clientImage: selectedImage.toBase64PNG(),
            clientMask: clientMask?.toBase64PNG(),
            connectionKey: connectionKey,
            connectionSecret: connectionSecret
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

    var hasConnection: Bool {
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
        prompt = ""
        negativePrompt = ""
    }
}
