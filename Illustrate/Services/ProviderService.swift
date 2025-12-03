import Foundation
import SwiftUI

class ProviderService: ObservableObject {
    static let shared = ProviderService()

    @Published private var _models: [ProviderModel] = []

    private init() {
        loadModels()
    }

    var allModels: [ProviderModel] {
        return _models
    }

    var activeModels: [ProviderModel] {
        return _models.filter { $0.active }
    }

    func models(for setType: EnumSetType) -> [ProviderModel] {
        return _models.filter { $0.modelSetType == setType && $0.active }
    }

    func models(for providerCode: EnumProviderCode) -> [ProviderModel] {
        return _models.filter { $0.providerId == providerCode.providerId && $0.active }
    }

    func models(for providerId: UUID) -> [ProviderModel] {
        return _models.filter { $0.providerId == providerId && $0.active }
    }

    func model(by modelId: String) -> ProviderModel? {
        return _models.first { $0.modelId.uuidString == modelId }
    }

    func model(by code: EnumProviderModelCode) -> ProviderModel? {
        return _models.first { $0.modelCode == code }
    }

    func isModelActive(_ code: EnumProviderModelCode) -> Bool {
        return model(by: code)?.active ?? false
    }

    func supportedDimensions(for modelId: String) -> [String] {
        return model(by: modelId)?.modelSupportedParams.dimensions ?? []
    }

    func maxPromptLength(for modelId: String) -> Int {
        return model(by: modelId)?.modelSupportedParams.maxPromptLength ?? 256
    }

    func isOpenAIConnected(providerKeys: [ProviderKey]) -> Bool {
        return providerKeys.contains { $0.providerId == EnumProviderCode.OPENAI.providerId }
    }

    private func loadModels() {
        _models = [
            OpenAIModels.createModels(),
            StabilityModels.createModels(),
            GoogleCloudModels.createModels(),
            ReplicateModels.createModels(),
            FALModels.createModels()
        ].flatMap { $0 }
    }

    func refreshModels() {
        loadModels()
    }
}

struct ProviderServiceKey: EnvironmentKey {
    static let defaultValue = ProviderService.shared
}

extension EnvironmentValues {
    var providerService: ProviderService {
        get { self[ProviderServiceKey.self] }
        set { self[ProviderServiceKey.self] = newValue }
    }
}
