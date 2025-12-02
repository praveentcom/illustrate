import Foundation

protocol ConnectionServiceProtocol {
    var allModels: [ConnectionModel] { get }

    func models(for type: EnumSetType) -> [ConnectionModel]
    func model(by id: String) -> ConnectionModel?
    func isOpenAIConnected(connectionKeys: [ConnectionKey]) -> Bool
}