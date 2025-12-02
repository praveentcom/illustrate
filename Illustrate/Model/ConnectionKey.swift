import Foundation
import SwiftData

let TEAM_ID = "24J6SG2424"
var keychainAccessGroup = "\(TEAM_ID).so.illustrate.SharedItems"

@Model
final class ConnectionKey: Codable {
    enum CodingKeys: CodingKey {
        case connectionId
        case createdAt
    }

    var connectionId: UUID = UUID()
    var createdAt: Date = Date()

    init(connectionId: UUID, createdAt: Date = Date()) {
        self.connectionId = connectionId
        self.createdAt = createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(createdAt, forKey: .createdAt)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionId = try container.decode(UUID.self, forKey: .connectionId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
