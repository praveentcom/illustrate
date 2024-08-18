import Foundation
import SwiftData

@Model
final class PartnerKey: Codable {
    enum CodingKeys: CodingKey {
        case partnerId
        case value
        case createdAt
        case active
        case creditCurrency
        case creditUsed
        case totalRequests
    }
    
    var partnerId: UUID
    var value: String
    var createdAt: Date
    var active: Bool
    var creditCurrency: EnumPartnerCreditCurrency
    var creditUsed: Decimal
    var totalRequests: Int

    init(partnerId: UUID, value: String, createdAt: Date = Date(), active: Bool = true, creditCurrency: EnumPartnerCreditCurrency = EnumPartnerCreditCurrency.USD, creditUsed: Decimal = 0.0, totalRequests: Int = 0) {
        self.partnerId = partnerId
        self.value = value
        self.createdAt = createdAt
        self.active = active
        self.creditCurrency = creditCurrency
        self.creditUsed = creditUsed
        self.totalRequests = totalRequests
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partnerId, forKey: .partnerId)
        try container.encode(value, forKey: .value)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(active, forKey: .active)
        try container.encode(creditCurrency, forKey: .creditCurrency)
        try container.encode(creditUsed, forKey: .creditUsed)
        try container.encode(totalRequests, forKey: .totalRequests)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partnerId = try container.decode(UUID.self, forKey: .partnerId)
        value = try container.decode(String.self, forKey: .value)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        active = try container.decode(Bool.self, forKey: .active)
        creditCurrency = try container.decode(EnumPartnerCreditCurrency.self, forKey: .creditCurrency)
        creditUsed = try container.decode(Decimal.self, forKey: .creditUsed)
        totalRequests = try container.decode(Int.self, forKey: .totalRequests)
    }
}
