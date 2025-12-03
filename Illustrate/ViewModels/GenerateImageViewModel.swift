import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

@MainActor
class GenerateImageViewModel: ObservableObject {
    private let modelContext: ModelContext?
    private let connectionService: ConnectionService
    private let keychain: KeychainSwift

    @Published var selectedConnectionId: String = ""
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

        return connectionService.allModels.filter {
            $0.modelSetType == .GENERATE &&
            $0.connectionId.uuidString == selectedConnectionId &&
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
                $0.connectionId == connection.connectionId && $0.modelSetType == .GENERATE && $0.active
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

    func validateAndSetDimensions() {
        let selectedModel = getSelectedModel()
        let supportedDimensions = selectedModel?.modelSupportedParams.dimensions ?? []

        if artDimensions.isEmpty {
            artDimensions = supportedDimensions.first ?? ""
        } else if !supportedDimensions.contains(artDimensions) {
            artDimensions = supportedDimensions.first ?? ""
        }
    }

    func generateImage(connectionKeys: [ConnectionKey]) async -> ImageSetResponse? {
        guard !isGenerating,
              let selectedModel = getSelectedModel() else {
            return nil
        }

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
                connectionKey: connectionKey,
                connectionSecret: secret,
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

    var hasConnection: Bool {
        return !selectedModelId.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}
