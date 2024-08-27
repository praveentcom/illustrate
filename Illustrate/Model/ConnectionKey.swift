import Foundation
import SwiftData

var keychainAccessGroup = "JV227HA2DR.so.illustrate.SharedItems"

@Model
final class ConnectionKey: Codable {
    enum CodingKeys: CodingKey {
        case connectionId
        case createdAt
        case active
        case creditCurrency
        case creditUsed
        case totalRequests
    }

    var connectionId: UUID = UUID()
    var createdAt: Date = Date()
    var active: Bool = true
    var creditCurrency: EnumConnectionCreditCurrency = EnumConnectionCreditCurrency.USD
    var creditUsed: Decimal = 0.0
    var totalRequests: Int = 0

    init(connectionId: UUID, createdAt: Date = Date(), active: Bool = true, creditCurrency: EnumConnectionCreditCurrency = EnumConnectionCreditCurrency.USD, creditUsed: Decimal = 0.0, totalRequests: Int = 0) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.active = active
        self.creditCurrency = creditCurrency
        self.creditUsed = creditUsed
        self.totalRequests = totalRequests
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(active, forKey: .active)
        try container.encode(creditCurrency, forKey: .creditCurrency)
        try container.encode(creditUsed, forKey: .creditUsed)
        try container.encode(totalRequests, forKey: .totalRequests)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionId = try container.decode(UUID.self, forKey: .connectionId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        active = try container.decode(Bool.self, forKey: .active)
        creditCurrency = try container.decode(EnumConnectionCreditCurrency.self, forKey: .creditCurrency)
        creditUsed = try container.decode(Decimal.self, forKey: .creditUsed)
        totalRequests = try container.decode(Int.self, forKey: .totalRequests)
    }
}
