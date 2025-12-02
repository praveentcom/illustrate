import Foundation
import KeychainSwift
import SwiftData
import SwiftUI
import PhotosUI

@MainActor
class ImageToVideoViewModel: ObservableObject {
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
    @Published var numberOfVideos: Int = 1
    @Published var promptEnhanceOpted: Bool = false
    @Published var motion: Double = 135
    @Published var stickyness: Double = 2.0

    // MARK: - Photo Properties
    @Published var selectedImageItem: PhotosPickerItem?
    @Published var selectedImage: PlatformImage?
    @Published var colorPalette: [String] = []
    @Published var isPhotoPickerOpen: Bool = false
    @Published var isCropSheetOpen: Bool = false

    // MARK: - Focus State
    var focusedField: Field? = nil

    enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }

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
    func getSupportedModels(connectionKeys: [ConnectionKey]) -> [ConnectionModel] {
        guard !selectedConnectionId.isEmpty else { return [] }

        return connectionService.models(for: .VIDEO_IMAGE).filter {
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
                $0.connectionId == connection.connectionId && $0.modelSetType == .VIDEO_IMAGE
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

            let models = getSupportedModels(connectionKeys: connectionKeys)
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

        if let selectedImage = selectedImage {
            colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
        }

        isCropSheetOpen = false
    }

    func cancelImageCropping() {
        selectedImage = nil
        colorPalette = []
        isCropSheetOpen = false
    }

    // MARK: - Video Generation
    func generateVideo(connectionKeys: [ConnectionKey]) async -> VideoSetResponse? {
        guard !isGenerating,
              let selectedModel = getSelectedModel() else {
            return nil
        }

        // Get connection secret from keychain
        let connectionSecret = keychain.get(selectedModel.connectionId.uuidString)

        guard let secret = connectionSecret else {
            return VideoSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Keychain record not found"
            )
        }

        // Find connection key
        guard let connectionKey = connectionKeys.first(where: {
            $0.connectionId == selectedModel.connectionId
        }) else {
            return VideoSetResponse(
                status: .FAILED,
                errorCode: .ADAPTER_ERROR,
                errorMessage: "Connection key not found"
            )
        }

        await MainActor.run {
            isGenerating = true
        }

        do {
            let request = VideoGenerationRequest(
                modelId: selectedModel.modelId.uuidString,
                artDimensions: artDimensions,
                clientImage: selectedImage?.toBase64PNG(),
                connectionKey: connectionKey,
                connectionSecret: secret,
                motion: Int(motion),
                stickyness: Int(stickyness)
            )

            let adapter = GenerateVideoAdapter(
                videoGenerationRequest: request,
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
                    message: "Failed to generate video: \(error.localizedDescription)",
                    isShowing: true
                )
            }
            return nil
        }
    }

    // MARK: - Generation Handler
    func handleGenerationResponse(response: VideoSetResponse?) {
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
        return !isGenerating && selectedImage != nil && !selectedModelId.isEmpty
    }

    var hasConnection: Bool {
        return !selectedModelId.isEmpty
    }

    // MARK: - Cleanup
    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}
