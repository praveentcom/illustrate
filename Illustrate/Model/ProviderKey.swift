import Foundation
import SwiftData

let TEAM_ID = "24J6SG2424"
var keychainAccessGroup = "\(TEAM_ID).so.illustrate.SharedItems"

@Model
final class ProviderKey: Codable {
    enum CodingKeys: CodingKey {
        case providerId
        case createdAt
    }

    var providerId: UUID = UUID()
    var createdAt: Date = Date()

    init(providerId: UUID, createdAt: Date = Date()) {
        self.providerId = providerId
        self.createdAt = createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(providerId, forKey: .providerId)
        try container.encode(createdAt, forKey: .createdAt)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        providerId = try container.decode(UUID.self, forKey: .providerId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
