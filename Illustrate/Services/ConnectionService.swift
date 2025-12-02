import Foundation
import SwiftUI

class ConnectionService: ObservableObject {
    static let shared = ConnectionService()

    @Published private var _models: [ConnectionModel] = []

    private init() {
        loadModels()
    }

    var allModels: [ConnectionModel] {
        return _models
    }

    var activeModels: [ConnectionModel] {
        return _models.filter { $0.active }
    }

    func models(for setType: EnumSetType) -> [ConnectionModel] {
        return _models.filter { $0.modelSetType == setType && $0.active }
    }

    func models(for connectionCode: EnumConnectionCode) -> [ConnectionModel] {
        return _models.filter { $0.connectionId == connectionCode.connectionId && $0.active }
    }

    func models(for connectionId: UUID) -> [ConnectionModel] {
        return _models.filter { $0.connectionId == connectionId && $0.active }
    }

    func model(by modelId: String) -> ConnectionModel? {
        return _models.first { $0.modelId.uuidString == modelId }
    }

    func model(by code: EnumConnectionModelCode) -> ConnectionModel? {
        return _models.first { $0.modelCode == code }
    }

    func isModelActive(_ code: EnumConnectionModelCode) -> Bool {
        return model(by: code)?.active ?? false
    }

    func supportedDimensions(for modelId: String) -> [String] {
        return model(by: modelId)?.modelSupportedParams.dimensions ?? []
    }

    func maxPromptLength(for modelId: String) -> Int {
        return model(by: modelId)?.modelSupportedParams.maxPromptLength ?? 256
    }

    func isOpenAIConnected(connectionKeys: [ConnectionKey]) -> Bool {
        return connectionKeys.contains { $0.connectionId == EnumConnectionCode.OPENAI.connectionId }
    }

    private func loadModels() {
        _models = [
            OpenAIModels.createModels(),
            StabilityModels.createModels(),
            GoogleCloudModels.createModels(),
            ReplicateModels.createModels(),
            FALModels.createModels(),
            HuggingFaceModels.createModels()
        ].flatMap { $0 }
    }

    func refreshModels() {
        loadModels()
    }
}

struct ConnectionServiceKey: EnvironmentKey {
    static let defaultValue = ConnectionService.shared
}

extension EnvironmentValues {
    var connectionService: ConnectionService {
        get { self[ConnectionServiceKey.self] }
        set { self[ConnectionServiceKey.self] = newValue }
    }
}
