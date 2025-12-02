import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

@MainActor
class TextToVideoViewModel: ObservableObject {
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

        return connectionService.models(for: .VIDEO_TEXT).filter {
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
                $0.connectionId == connection.connectionId && $0.modelSetType == .VIDEO_TEXT
            }
        }
    }
    
    func getSupportedDurations() -> [Int] {
        guard let model = getSelectedModel() else { return [8] }
        let durations = model.modelSupportedParams.supportedDurations
        return durations.isEmpty ? [8] : durations
    }
    
    var is1080p: Bool {
        return artDimensions.contains("1080") || artDimensions.contains("1920")
    }
    
    func getAvailableDurations() -> [Int] {
        let allDurations = getSupportedDurations()
        if is1080p {
            return [8]
        }
        return allDurations
    }
    
    var supportsAudio: Bool {
        return getSelectedModel()?.modelSupportedParams.supportsAudio ?? false
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
        
        let supportedDurations = getSupportedDurations()
        if !supportedDurations.contains(durationSeconds) {
            durationSeconds = supportedDurations.last ?? 8
        }
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
                message: "Prompt is required to generate a video",
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
        
        let resolution = artDimensions.contains("1080") || artDimensions.contains("1920") ? "1080p" : "720p"

        let request = VideoGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            artDimensions: artDimensions,
            connectionKey: connectionKey,
            connectionSecret: connectionSecret,
            durationSeconds: durationSeconds,
            resolution: resolution,
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

    var hasConnection: Bool {
        return !selectedModelId.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}
