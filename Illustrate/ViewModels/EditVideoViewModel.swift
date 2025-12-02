import AVFoundation
import Foundation
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
class EditVideoViewModel: ObservableObject {
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
    @Published var durationSeconds: Int = 8
    @Published var generateAudio: Bool = true

    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var selectedVideoData: Data?
    @Published var selectedVideoThumbnail: PlatformImage?
    @Published var selectedVideoURL: URL?
    @Published var isVideoPickerOpen: Bool = false
    @Published var isVideoPreviewOpen: Bool = false
    @Published var isProcessingVideo: Bool = false

    var focusedField: Field? = nil

    enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }

    init(
        connectionService: ConnectionService = ConnectionService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.connectionService = connectionService
        self.keychain = keychain

        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

    func getSupportedModels(connectionKeys: [ConnectionKey]) -> [ConnectionModel] {
        guard !selectedConnectionId.isEmpty else { return [] }

        return connectionService.allModels.filter {
            $0.connectionId.uuidString == selectedConnectionId &&
            $0.modelSupportedParams.supportsVideoInput &&
            $0.active
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
                $0.connectionId == connection.connectionId &&
                $0.modelSupportedParams.supportsVideoInput
            }
        }
    }

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

    func validateAndSetDimensions() {
        let selectedModel = getSelectedModel()
        let supportedDimensions = selectedModel?.modelSupportedParams.dimensions ?? []

        if artDimensions.isEmpty {
            artDimensions = supportedDimensions.first ?? ""
        } else if !supportedDimensions.contains(artDimensions) {
            artDimensions = supportedDimensions.first ?? ""
        }
    }
    
    func getAvailableDurations() -> [Int] {
        return [8]
    }

    func processSelectedVideo() async {
        guard let videoItem = selectedVideoItem else { return }
        
        isProcessingVideo = true
        
        do {
            if let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) {
                selectedVideoData = movie.data
                selectedVideoThumbnail = await generateThumbnail(from: movie.data)
            }
        } catch {
            errorState = ErrorState(
                message: "Failed to load video: \(error.localizedDescription)",
                isShowing: true
            )
        }
        
        isProcessingVideo = false
    }
    
    private func generateThumbnail(from videoData: Data) async -> PlatformImage? {
        if let oldURL = selectedVideoURL {
            try? FileManager.default.removeItem(at: oldURL)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        do {
            try videoData.write(to: tempURL)
            selectedVideoURL = tempURL
            
            let asset = AVURLAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            
            #if os(macOS)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            #else
            return UIImage(cgImage: cgImage)
            #endif
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            selectedVideoURL = nil
            return nil
        }
    }

    func clearVideo() {
        if let url = selectedVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
        selectedVideoItem = nil
        selectedVideoData = nil
        selectedVideoThumbnail = nil
        selectedVideoURL = nil
    }

    func submitToQueue(connectionKeys: [ConnectionKey], queueManager: QueueManager, modelContext: ModelContext) {
        guard let selectedModel = getSelectedModel() else {
            errorState = ErrorState(
                message: "No model selected",
                isShowing: true
            )
            return
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorState = ErrorState(
                message: "Prompt is required to extend the video",
                isShowing: true
            )
            return
        }
        
        guard let videoData = selectedVideoData else {
            errorState = ErrorState(
                message: "Please select a video to extend",
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

        let request = VideoGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            artDimensions: artDimensions,
            clientVideo: videoData.base64EncodedString(),
            connectionKey: connectionKey,
            connectionSecret: connectionSecret,
            durationSeconds: durationSeconds,
            resolution: "720p",
            generateAudio: generateAudio
        )

        _ = queueManager.submitVideoGeneration(
            request: request,
            modelContext: modelContext
        )

        showQueuedToast = true
    }

    var canGenerate: Bool {
        return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               selectedVideoData != nil && 
               !selectedModelId.isEmpty
    }

    var hasConnection: Bool {
        return !selectedModelId.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}

struct VideoTransferable: Transferable {
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .movie) { data in
            VideoTransferable(data: data)
        }
    }
}

