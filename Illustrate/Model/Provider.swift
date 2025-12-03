import Foundation
import SwiftData
import SwiftUI

enum EnumProviderCode: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case GOOGLE_CLOUD
    case OPENAI
    case STABILITY_AI
    case REPLICATE
    case FAL_AI

    var providerId: UUID {
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
        }
    }
}

enum EnumProviderKeyType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case JSON
    case API = "API Key"
}

enum EnumProviderCreditCurrency: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case USD
    case CREDITS = "Credits"
}

@Model
final class Provider: Codable, Identifiable {
    enum CodingKeys: CodingKey {
        case providerId
        case providerCode
        case providerName
        case providerDescription
        case providerOnboardingUrl
        case keyStructure
        case keyPlaceholder
        case keyType
        case creditCurrency
        case active
    }

    var providerId: UUID = UUID()
    var providerCode: EnumProviderCode = EnumProviderCode.OPENAI
    var providerName: String = "OpenAI"
    var providerDescription: String = ""
    var providerOnboardingUrl: String = ""
    var keyStructure: String = ""
    var keyPlaceholder: String = ""
    var keyType: EnumProviderKeyType = EnumProviderKeyType.JSON
    var creditCurrency: EnumProviderCreditCurrency = EnumProviderCreditCurrency.USD
    var active: Bool = true

    init(providerId: UUID, providerCode: EnumProviderCode, providerName: String, providerDescription: String, providerOnboardingUrl: String, keyStructure: String, keyPlaceholder: String, keyType: EnumProviderKeyType, creditCurrency: EnumProviderCreditCurrency, active: Bool) {
        self.providerId = providerId
        self.providerCode = providerCode
        self.providerName = providerName
        self.providerDescription = providerDescription
        self.providerOnboardingUrl = providerOnboardingUrl
        self.keyStructure = keyStructure
        self.keyPlaceholder = keyPlaceholder
        self.keyType = keyType
        self.creditCurrency = creditCurrency
        self.active = active
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        providerId = try container.decode(UUID.self, forKey: .providerId)
        providerCode = try container.decode(EnumProviderCode.self, forKey: .providerCode)
        providerName = try container.decode(String.self, forKey: .providerName)
        providerDescription = try container.decode(String.self, forKey: .providerDescription)
        providerOnboardingUrl = try container.decode(String.self, forKey: .providerOnboardingUrl)
        keyStructure = try container.decode(String.self, forKey: .keyStructure)
        keyPlaceholder = try container.decode(String.self, forKey: .keyPlaceholder)
        keyType = try container.decode(EnumProviderKeyType.self, forKey: .keyType)
        creditCurrency = try container.decode(EnumProviderCreditCurrency.self, forKey: .creditCurrency)
        active = try container.decode(Bool.self, forKey: .active)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(providerId, forKey: .providerId)
        try container.encode(providerCode, forKey: .providerCode)
        try container.encode(providerName, forKey: .providerName)
        try container.encode(providerDescription, forKey: .providerDescription)
        try container.encode(providerOnboardingUrl, forKey: .providerOnboardingUrl)
        try container.encode(keyStructure, forKey: .keyStructure)
        try container.encode(keyPlaceholder, forKey: .keyPlaceholder)
        try container.encode(keyType, forKey: .keyType)
        try container.encode(creditCurrency, forKey: .creditCurrency)
        try container.encode(active, forKey: .active)
    }
}

func getProvider(modelId: String) -> Provider? {
    let model = ProviderService.shared.model(by: modelId)
    return providers.first(where: { $0.providerId == model?.providerId })
}

func getProvider(providerId: UUID) -> Provider? {
    return providers.first(where: { $0.providerId == providerId })
}

struct ProviderLabel: View {
    var provider: Provider

    var body: some View {
        HStack {
            Image("\(provider.providerCode)_square".lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(provider.providerName)
        }
    }
}

let providers = [
    Provider(
        providerId: EnumProviderCode.OPENAI.providerId,
        providerCode: EnumProviderCode.OPENAI,
        providerName: "OpenAI",
        providerDescription: "Creating safe AGI that benefits all of humanity.",
        providerOnboardingUrl: "https://platform.openai.com/docs/overview",
        keyStructure: "^sk-proj-[a-zA-Z0-9]{32}$",
        keyPlaceholder: "sk-proj-************",
        keyType: EnumProviderKeyType.API,
        creditCurrency: EnumProviderCreditCurrency.USD,
        active: true
    ),
    Provider(
        providerId: EnumProviderCode.STABILITY_AI.providerId,
        providerCode: EnumProviderCode.STABILITY_AI,
        providerName: "Stability AI",
        providerDescription: "World’s leading open source generative AI company.",
        providerOnboardingUrl: "https://platform.stability.ai/docs/api-reference",
        keyStructure: "^sk-[a-zA-Z0-9]{38}$",
        keyPlaceholder: "sk-************",
        keyType: EnumProviderKeyType.API,
        creditCurrency: EnumProviderCreditCurrency.CREDITS,
        active: true
    ),
    Provider(
        providerId: EnumProviderCode.GOOGLE_CLOUD.providerId,
        providerCode: EnumProviderCode.GOOGLE_CLOUD,
        providerName: "Google Cloud",
        providerDescription: "High-performance infrastructure for cloud.",
        providerOnboardingUrl: "https://console.cloud.google.com/apis/credentials",
        keyStructure: "^AIza[a-zA-Z0-9_-]{35}$",
        keyPlaceholder: "AIza************",
        keyType: EnumProviderKeyType.API,
        creditCurrency: EnumProviderCreditCurrency.USD,
        active: true
    ),
    Provider(
        providerId: EnumProviderCode.REPLICATE.providerId,
        providerCode: EnumProviderCode.REPLICATE,
        providerName: "Replicate",
        providerDescription: "Making ML accessible to every software developer.",
        providerOnboardingUrl: "https://replicate.com",
        keyStructure: "^r8_[a-zA-Z0-9]{38}$",
        keyPlaceholder: "r8_************",
        keyType: EnumProviderKeyType.API,
        creditCurrency: EnumProviderCreditCurrency.USD,
        active: true
    ),
    Provider(
        providerId: EnumProviderCode.FAL_AI.providerId,
        providerCode: EnumProviderCode.FAL_AI,
        providerName: "Fal AI",
        providerDescription: "Fast, reliable, cheap. Lightning fast inference.",
        providerOnboardingUrl: "https://fal.ai",
        keyStructure: "^$",
        keyPlaceholder: "********-****-****-****-************:*******************",
        keyType: EnumProviderKeyType.API,
        creditCurrency: EnumProviderCreditCurrency.USD,
        active: true
    ),
]
