import Foundation
import SwiftData
import SwiftUI

enum EnumPartnerCode: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case GOOGLE_CLOUD = "Google Cloud"
    case OPENAI = "OpenAI"
    case STABILITY_AI = "Stability AI"
    case REPLICATE = "Replicate"
}

enum EnumPartnerKeyType: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case JSON = "JSON"
    case API = "API Key"
}

enum EnumPartnerCreditCurrency: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case USD = "USD"
    case CREDITS = "Credits"
}

@Model
final class Partner: Codable, Identifiable {
    enum CodingKeys: CodingKey {
        case partnerId
        case partnerCode
        case partnerName
        case partnerDescription
        case keyStructure
        case keyType
        case creditCurrency
        case active
    }
    
    var partnerId: UUID
    var partnerCode: EnumPartnerCode
    var partnerName: String
    var partnerDescription: String
    var keyStructure: String
    var keyType: EnumPartnerKeyType
    var creditCurrency: EnumPartnerCreditCurrency
    var active: Bool
    
    init(partnerId: UUID, partnerCode: EnumPartnerCode, partnerName: String, partnerDescription: String, keyStructure: String, keyType: EnumPartnerKeyType, creditCurrency: EnumPartnerCreditCurrency, active: Bool) {
        self.partnerId = partnerId
        self.partnerCode = partnerCode
        self.partnerName = partnerName
        self.partnerDescription = partnerDescription
        self.keyStructure = keyStructure
        self.keyType = keyType
        self.creditCurrency = creditCurrency
        self.active = active
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partnerId = try container.decode(UUID.self, forKey: .partnerId)
        partnerCode = try container.decode(EnumPartnerCode.self, forKey: .partnerCode)
        partnerName = try container.decode(String.self, forKey: .partnerName)
        partnerDescription = try container.decode(String.self, forKey: .partnerDescription)
        keyStructure = try container.decode(String.self, forKey: .keyStructure)
        keyType = try container.decode(EnumPartnerKeyType.self, forKey: .keyType)
        creditCurrency = try container.decode(EnumPartnerCreditCurrency.self, forKey: .creditCurrency)
        active = try container.decode(Bool.self, forKey: .active)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partnerId, forKey: .partnerId)
        try container.encode(partnerCode, forKey: .partnerCode)
        try container.encode(partnerName, forKey: .partnerName)
        try container.encode(partnerDescription, forKey: .partnerDescription)
        try container.encode(keyStructure, forKey: .keyStructure)
        try container.encode(keyType, forKey: .keyType)
        try container.encode(creditCurrency, forKey: .creditCurrency)
        try container.encode(active, forKey: .active)
    }
}

func getPartner(modelId: String) -> Partner? {
    let model = getModel(modelId: modelId)
    return partners.first(where: { $0.partnerId == model?.partnerId })
}

func getPartner(partnerId: UUID) -> Partner? {
    return partners.first(where: { $0.partnerId == partnerId })
}

struct PartnerLabel: View {
    var partner: Partner
    
    var body: some View {
        HStack {
            Image("\(partner.partnerCode)_square".lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(partner.partnerName)
        }
    }
}

let partners = [
    Partner(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        partnerCode: EnumPartnerCode.OPENAI,
        partnerName: "OpenAI",
        partnerDescription: "Creating safe AGI that benefits all of humanity.",
        keyStructure: "^sk-proj-[a-zA-Z0-9]{32}$",
        keyType: EnumPartnerKeyType.API,
        creditCurrency: EnumPartnerCreditCurrency.USD,
        active: true
    ),
    Partner(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        partnerCode: EnumPartnerCode.STABILITY_AI,
        partnerName: "Stability AI",
        partnerDescription: "Stability AI is the world’s leading open source generative AI company.",
        keyStructure: "^sk-[a-zA-Z0-9]{38}$",
        keyType: EnumPartnerKeyType.API,
        creditCurrency: EnumPartnerCreditCurrency.CREDITS,
        active: true
    ),
    Partner(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
        partnerCode: EnumPartnerCode.GOOGLE_CLOUD,
        partnerName: "Google Cloud",
        partnerDescription: "High-performance infrastructure for cloud computing, data analytics & machine learning. Secure, reliable and high performance cloud services.",
        keyStructure: "\"project_id\":\\s*\"[a-z0-9\\-]+\",\\s*\"private_key\":\\s*\"-----BEGIN PRIVATE KEY-----\\\\n(?:[^\\\\n]+\\\\n)+-----END PRIVATE KEY-----\\\\n\",\\s*\"client_email\":\\s*\"[a-z0-9\\-]+@[a-z0-9\\-]+\\.iam\\.gserviceaccount\\.com\"",
        keyType: EnumPartnerKeyType.JSON,
        creditCurrency: EnumPartnerCreditCurrency.USD,
        active: true
    ),
    Partner(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
        partnerCode: EnumPartnerCode.REPLICATE,
        partnerName: "Replicate",
        partnerDescription: "Replicate is making machine learning accessible to every software developer.",
        keyStructure: "^r8_-[a-zA-Z0-9]{38}$",
        keyType: EnumPartnerKeyType.API,
        creditCurrency: EnumPartnerCreditCurrency.USD,
        active: true
    ),
]
