import Foundation
import SwiftData
import SwiftUI

enum EnumConnectionCode: String, Codable, CaseIterable, Identifiable {
    var id: String { UUID().uuidString }

    case GOOGLE_CLOUD
    case OPENAI
    case STABILITY_AI
    case REPLICATE
    case FAL_AI
    case HUGGING_FACE

    var connectionId: UUID {
        switch self {
        case .GOOGLE_CLOUD:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        case .OPENAI:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        case .STABILITY_AI:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
        case .REPLICATE:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
        case .FAL_AI:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
        case .HUGGING_FACE:
            return UUID(uuidString: "10000000-0000-0000-0000-000000000006")!
        }
    }
}

enum EnumConnectionKeyType: String, Codable, CaseIterable, Identifiable {
    var id: String { UUID().uuidString }

    case JSON
    case API = "API Key"
}

enum EnumConnectionCreditCurrency: String, Codable, CaseIterable, Identifiable {
    var id: String { UUID().uuidString }

    case USD
    case CREDITS = "Credits"
}

@Model
final class Connection: Codable, Identifiable {
    enum CodingKeys: CodingKey {
        case connectionId
        case connectionCode
        case connectionName
        case connectionDescription
        case connectionOnboardingUrl
        case keyStructure
        case keyPlaceholder
        case keyType
        case creditCurrency
        case active
    }

    var connectionId: UUID = UUID()
    var connectionCode: EnumConnectionCode = EnumConnectionCode.OPENAI
    var connectionName: String = "OpenAI"
    var connectionDescription: String = ""
    var connectionOnboardingUrl: String = ""
    var keyStructure: String = ""
    var keyPlaceholder: String = ""
    var keyType: EnumConnectionKeyType = EnumConnectionKeyType.JSON
    var creditCurrency: EnumConnectionCreditCurrency = EnumConnectionCreditCurrency.USD
    var active: Bool = true

    init(connectionId: UUID, connectionCode: EnumConnectionCode, connectionName: String, connectionDescription: String, connectionOnboardingUrl: String, keyStructure: String, keyPlaceholder: String, keyType: EnumConnectionKeyType, creditCurrency: EnumConnectionCreditCurrency, active: Bool) {
        self.connectionId = connectionId
        self.connectionCode = connectionCode
        self.connectionName = connectionName
        self.connectionDescription = connectionDescription
        self.connectionOnboardingUrl = connectionOnboardingUrl
        self.keyStructure = keyStructure
        self.keyPlaceholder = keyPlaceholder
        self.keyType = keyType
        self.creditCurrency = creditCurrency
        self.active = active
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionId = try container.decode(UUID.self, forKey: .connectionId)
        connectionCode = try container.decode(EnumConnectionCode.self, forKey: .connectionCode)
        connectionName = try container.decode(String.self, forKey: .connectionName)
        connectionDescription = try container.decode(String.self, forKey: .connectionDescription)
        connectionOnboardingUrl = try container.decode(String.self, forKey: .connectionOnboardingUrl)
        keyStructure = try container.decode(String.self, forKey: .keyStructure)
        keyPlaceholder = try container.decode(String.self, forKey: .keyPlaceholder)
        keyType = try container.decode(EnumConnectionKeyType.self, forKey: .keyType)
        creditCurrency = try container.decode(EnumConnectionCreditCurrency.self, forKey: .creditCurrency)
        active = try container.decode(Bool.self, forKey: .active)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(connectionCode, forKey: .connectionCode)
        try container.encode(connectionName, forKey: .connectionName)
        try container.encode(connectionDescription, forKey: .connectionDescription)
        try container.encode(connectionOnboardingUrl, forKey: .connectionOnboardingUrl)
        try container.encode(keyStructure, forKey: .keyStructure)
        try container.encode(keyPlaceholder, forKey: .keyPlaceholder)
        try container.encode(keyType, forKey: .keyType)
        try container.encode(creditCurrency, forKey: .creditCurrency)
        try container.encode(active, forKey: .active)
    }
}

func getConnection(modelId: String) -> Connection? {
    let model = getModel(modelId: modelId)
    return connections.first(where: { $0.connectionId == model?.connectionId })
}

func getConnection(connectionId: UUID) -> Connection? {
    return connections.first(where: { $0.connectionId == connectionId })
}

struct ConnectionLabel: View {
    var connection: Connection

    var body: some View {
        HStack {
            Image("\(connection.connectionCode)_square".lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(connection.connectionName)
        }
    }
}

let connections = [
    Connection(
        connectionId: EnumConnectionCode.OPENAI.connectionId,
        connectionCode: EnumConnectionCode.OPENAI,
        connectionName: "OpenAI",
        connectionDescription: "Creating safe AGI that benefits all of humanity.",
        connectionOnboardingUrl: "https://platform.openai.com/docs/overview",
        keyStructure: "^sk-proj-[a-zA-Z0-9]{32}$",
        keyPlaceholder: "sk-proj-************",
        keyType: EnumConnectionKeyType.API,
        creditCurrency: EnumConnectionCreditCurrency.USD,
        active: true
    ),
    Connection(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        connectionCode: EnumConnectionCode.STABILITY_AI,
        connectionName: "Stability AI",
        connectionDescription: "World’s leading open source generative AI company.",
        connectionOnboardingUrl: "https://platform.stability.ai/docs/api-reference",
        keyStructure: "^sk-[a-zA-Z0-9]{38}$",
        keyPlaceholder: "sk-************",
        keyType: EnumConnectionKeyType.API,
        creditCurrency: EnumConnectionCreditCurrency.CREDITS,
        active: true
    ),
//    Connection(
//        connectionId: EnumConnectionCode.GOOGLE_CLOUD.connectionId,
//        connectionCode: EnumConnectionCode.GOOGLE_CLOUD,
//        connectionName: "Google Cloud",
//        connectionDescription: "High-performance infrastructure for cloud.",
//        keyStructure: "\"project_id\":\\s*\"[a-z0-9\\-]+\",\\s*\"private_key\":\\s*\"-----BEGIN PRIVATE KEY-----\\\\n(?:[^\\\\n]+\\\\n)+-----END PRIVATE KEY-----\\\\n\",\\s*\"client_email\":\\s*\"[a-z0-9\\-]+@[a-z0-9\\-]+\\.iam\\.gserviceaccount\\.com\"",
//        keyPlaceholder: "Enter JSON key",
//        keyType: EnumConnectionKeyType.JSON,
//        creditCurrency: EnumConnectionCreditCurrency.USD,
//        active: true
//    ),
    Connection(
        connectionId: EnumConnectionCode.REPLICATE.connectionId,
        connectionCode: EnumConnectionCode.REPLICATE,
        connectionName: "Replicate",
        connectionDescription: "Making ML accessible to every software developer.",
        connectionOnboardingUrl: "https://replicate.com",
        keyStructure: "^r8_[a-zA-Z0-9]{38}$",
        keyPlaceholder: "r8_************",
        keyType: EnumConnectionKeyType.API,
        creditCurrency: EnumConnectionCreditCurrency.USD,
        active: true
    ),
    Connection(
        connectionId: EnumConnectionCode.FAL_AI.connectionId,
        connectionCode: EnumConnectionCode.FAL_AI,
        connectionName: "Fal AI",
        connectionDescription: "Fast, reliable, cheap. Lightning fast inference.",
        connectionOnboardingUrl: "https://fal.ai",
        keyStructure: "^$",
        keyPlaceholder: "********-****-****-****-************:*******************",
        keyType: EnumConnectionKeyType.API,
        creditCurrency: EnumConnectionCreditCurrency.USD,
        active: true
    ),
    Connection(
        connectionId: EnumConnectionCode.HUGGING_FACE.connectionId,
        connectionCode: EnumConnectionCode.HUGGING_FACE,
        connectionName: "Hugging Face",
        connectionDescription: "The AI community building the future.",
        connectionOnboardingUrl: "https://huggingface.co",
        keyStructure: "^hf_[a-zA-Z0-9]{38}$",
        keyPlaceholder: "hf_************",
        keyType: EnumConnectionKeyType.API,
        creditCurrency: EnumConnectionCreditCurrency.USD,
        active: true
    ),
]
