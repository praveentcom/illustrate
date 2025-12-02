import Foundation
import SwiftData
import SwiftUI

enum EnumConnectionModelCode: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case OPENAI_DALLE3
    case STABILITY_SDXL
    case STABILITY_SD3
    case STABILITY_SD3_TURBO
    case STABILITY_SD35_LARGE
    case STABILITY_SD35_LARGE_TURBO
    case STABILITY_SD35_MEDIUM
    case STABILITY_SD35_FLASH
    case STABILITY_CORE
    case STABILITY_ULTRA
    case STABILITY_CONSERVATIVE_UPSCALE
    case STABILITY_CREATIVE_UPSCALE
    case STABILITY_ERASE
    case STABILITY_INPAINT
    case STABILITY_OUTPAINT
    case STABILITY_SEARCH_AND_REPLACE
    case STABILITY_REMOVE_BACKGROUND
    case STABILITY_IMAGE_TO_VIDEO
    case REPLICATE_FLUX_SCHNELL
    case REPLICATE_FLUX_DEV
    case REPLICATE_FLUX_PRO
    case FAL_FLUX_SCHNELL
    case FAL_FLUX_DEV
    case FAL_FLUX_PRO
    case HUGGING_FACE_FLUX_SCHNELL
    case HUGGING_FACE_FLUX_DEV
    case GOOGLE_GEMINI_FLASH_IMAGE
    case GOOGLE_GEMINI_FLASH_IMAGE_EDIT
    case GOOGLE_GEMINI_PRO_IMAGE
    case GOOGLE_GEMINI_PRO_IMAGE_EDIT
    case GOOGLE_IMAGEN_3
    case GOOGLE_IMAGEN_4_FAST
    case GOOGLE_IMAGEN_4_STANDARD
    case GOOGLE_IMAGEN_4_ULTRA
    case GOOGLE_VEO_31
    case GOOGLE_VEO_31_FAST
    case GOOGLE_VEO_3
    case GOOGLE_VEO_3_FAST
    case GOOGLE_VEO_2

    var modelId: UUID {
        switch self {
        case .OPENAI_DALLE3:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000101")!
        case .STABILITY_SDXL:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000201")!
        case .STABILITY_SD3:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000202")!
        case .STABILITY_SD3_TURBO:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000203")!
        case .STABILITY_SD35_LARGE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000214")!
        case .STABILITY_SD35_LARGE_TURBO:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000215")!
        case .STABILITY_SD35_MEDIUM:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000216")!
        case .STABILITY_SD35_FLASH:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000217")!
        case .STABILITY_CORE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000204")!
        case .STABILITY_ULTRA:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000205")!
        case .STABILITY_CONSERVATIVE_UPSCALE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000206")!
        case .STABILITY_CREATIVE_UPSCALE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000207")!
        case .STABILITY_ERASE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000208")!
        case .STABILITY_INPAINT:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000209")!
        case .STABILITY_OUTPAINT:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000210")!
        case .STABILITY_SEARCH_AND_REPLACE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000211")!
        case .STABILITY_REMOVE_BACKGROUND:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000212")!
        case .STABILITY_IMAGE_TO_VIDEO:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000213")!
        case .REPLICATE_FLUX_SCHNELL:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000401")!
        case .REPLICATE_FLUX_DEV:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000402")!
        case .REPLICATE_FLUX_PRO:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000403")!
        case .FAL_FLUX_SCHNELL:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000501")!
        case .FAL_FLUX_DEV:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000502")!
        case .FAL_FLUX_PRO:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000503")!
        case .HUGGING_FACE_FLUX_SCHNELL:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000601")!
        case .HUGGING_FACE_FLUX_DEV:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000602")!
        case .GOOGLE_GEMINI_FLASH_IMAGE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000302")!
        case .GOOGLE_GEMINI_FLASH_IMAGE_EDIT:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000303")!
        case .GOOGLE_GEMINI_PRO_IMAGE:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000304")!
        case .GOOGLE_GEMINI_PRO_IMAGE_EDIT:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000305")!
        case .GOOGLE_IMAGEN_3:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000306")!
        case .GOOGLE_IMAGEN_4_FAST:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000307")!
        case .GOOGLE_IMAGEN_4_STANDARD:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000308")!
        case .GOOGLE_IMAGEN_4_ULTRA:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000309")!
        case .GOOGLE_VEO_31:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000310")!
        case .GOOGLE_VEO_31_FAST:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000311")!
        case .GOOGLE_VEO_3:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000312")!
        case .GOOGLE_VEO_3_FAST:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000313")!
        case .GOOGLE_VEO_2:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000314")!
        }
    }
}

enum EnumResponseModality: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case TEXT = "TEXT"
    case IMAGE = "IMAGE"
    case AUDIO = "AUDIO"
    
    var label: String {
        switch self {
        case .TEXT: return "Text"
        case .IMAGE: return "Image"
        case .AUDIO: return "Audio"
        }
    }
    
    var icon: String {
        switch self {
        case .TEXT: return "text.alignleft"
        case .IMAGE: return "photo"
        case .AUDIO: return "waveform"
        }
    }
}

struct ConnectionModelSupportParams: Codable {
    enum CodingKeys: CodingKey {
        case prompt
        case negativePrompt
        case maxPromptLength
        case dimensions
        case quality
        case variant
        case style
        case count
        case autoEnhance
        case responseModalities
        case supportedDurations
        case supportsAudio
        case supportsLastFrame
        case supportsVideoInput
    }

    var prompt: Bool = false
    var negativePrompt: Bool = false
    var maxPromptLength: Int = 256
    var dimensions: [String] = []
    var quality: Bool = false
    var variant: Bool = false
    var style: Bool = false
    var count: Int = 1
    var autoEnhance: Bool = false
    var responseModalities: [EnumResponseModality] = []
    var supportedDurations: [Int] = []
    var supportsAudio: Bool = false
    var supportsLastFrame: Bool = false
    var supportsVideoInput: Bool = false

    init(
        prompt: Bool,
        negativePrompt: Bool,
        maxPromptLength: Int,
        dimensions: [String],
        quality: Bool,
        variant: Bool,
        style: Bool,
        count: Int,
        autoEnhance: Bool,
        responseModalities: [EnumResponseModality] = [],
        supportedDurations: [Int] = [],
        supportsAudio: Bool = false,
        supportsLastFrame: Bool = false,
        supportsVideoInput: Bool = false
    ) {
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.maxPromptLength = maxPromptLength
        self.dimensions = dimensions
        self.quality = quality
        self.variant = variant
        self.style = style
        self.count = count
        self.autoEnhance = autoEnhance
        self.responseModalities = responseModalities
        self.supportedDurations = supportedDurations
        self.supportsAudio = supportsAudio
        self.supportsLastFrame = supportsLastFrame
        self.supportsVideoInput = supportsVideoInput
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(negativePrompt, forKey: .negativePrompt)
        try container.encode(maxPromptLength, forKey: .maxPromptLength)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(quality, forKey: .quality)
        try container.encode(variant, forKey: .variant)
        try container.encode(style, forKey: .style)
        try container.encode(count, forKey: .count)
        try container.encode(autoEnhance, forKey: .autoEnhance)
        try container.encode(responseModalities, forKey: .responseModalities)
        try container.encode(supportedDurations, forKey: .supportedDurations)
        try container.encode(supportsAudio, forKey: .supportsAudio)
        try container.encode(supportsLastFrame, forKey: .supportsLastFrame)
        try container.encode(supportsVideoInput, forKey: .supportsVideoInput)
    }
}

@Model
final class ConnectionModel: Codable {
    enum CodingKeys: CodingKey {
        case connectionId
        case modelId
        case modelCode
        case modelSetType
        case modelName
        case modelDescription
        case modelSupportedParams
        case modelLaunchDate
        case modelDeprecationDate
        case modelGenerateBaseURL
        case modelStatusBaseURL
        case modelAPIDocumentationURL
        case active
    }

    var connectionId: UUID = UUID()
    var modelId: UUID = UUID()
    var modelCode: EnumConnectionModelCode = EnumConnectionModelCode.OPENAI_DALLE3
    var modelSetType: EnumSetType = EnumSetType.GENERATE
    var modelName: String = ""
    var modelDescription: String = ""
    var modelSupportedParams: ConnectionModelSupportParams = ConnectionModelSupportParams(
        prompt: false,
        negativePrompt: false,
        maxPromptLength: 256,
        dimensions: [],
        quality: false,
        variant: false,
        style: false,
        count: 1,
        autoEnhance: false
    )
    var modelLaunchDate: Date = Date()
    var modelDeprecationDate: Date? = nil
    var modelGenerateBaseURL: String = ""
    var modelStatusBaseURL: String? = nil
    var modelAPIDocumentationURL: String = ""
    var active: Bool = true

    init(
        connectionId: UUID,
        modelId: UUID,
        modelCode: EnumConnectionModelCode,
        modelSetType: EnumSetType,
        modelName: String,
        modelDescription: String,
        modelSupportedParams: ConnectionModelSupportParams,
        modelLaunchDate: Date,
        modelDeprecationDate: Date? = nil,
        modelGenerateBaseURL: String,
        modelStatusBaseURL: String? = nil,
        modelAPIDocumentationURL: String,
        active: Bool
    ) {
        self.connectionId = connectionId
        self.modelId = modelId
        self.modelCode = modelCode
        self.modelSetType = modelSetType
        self.modelName = modelName
        self.modelDescription = modelDescription
        self.modelSupportedParams = modelSupportedParams
        self.modelLaunchDate = modelLaunchDate
        self.modelDeprecationDate = modelDeprecationDate
        self.modelGenerateBaseURL = modelGenerateBaseURL
        self.modelStatusBaseURL = modelStatusBaseURL
        self.modelAPIDocumentationURL = modelAPIDocumentationURL
        self.active = active
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionId = try container.decode(UUID.self, forKey: .connectionId)
        modelId = try container.decode(UUID.self, forKey: .modelId)
        modelCode = try container.decode(EnumConnectionModelCode.self, forKey: .modelCode)
        modelSetType = try container.decode(EnumSetType.self, forKey: .modelSetType)
        modelName = try container.decode(String.self, forKey: .modelName)
        modelDescription = try container.decode(String.self, forKey: .modelDescription)
        modelSupportedParams = try container.decode(ConnectionModelSupportParams.self, forKey: .modelSupportedParams)
        modelLaunchDate = try container.decode(Date.self, forKey: .modelLaunchDate)
        modelDeprecationDate = try container.decodeIfPresent(Date.self, forKey: .modelDeprecationDate)
        modelGenerateBaseURL = try container.decode(String.self, forKey: .modelGenerateBaseURL)
        modelStatusBaseURL = try container.decodeIfPresent(String.self, forKey: .modelStatusBaseURL)
        modelAPIDocumentationURL = try container.decode(String.self, forKey: .modelAPIDocumentationURL)
        active = try container.decode(Bool.self, forKey: .active)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(modelCode, forKey: .modelCode)
        try container.encode(modelSetType, forKey: .modelSetType)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(modelDescription, forKey: .modelDescription)
        try container.encode(modelSupportedParams, forKey: .modelSupportedParams)
        try container.encode(modelLaunchDate, forKey: .modelLaunchDate)
        try container.encode(modelDeprecationDate, forKey: .modelDeprecationDate)
        try container.encode(modelGenerateBaseURL, forKey: .modelGenerateBaseURL)
        try container.encode(modelStatusBaseURL, forKey: .modelStatusBaseURL)
        try container.encode(modelAPIDocumentationURL, forKey: .modelAPIDocumentationURL)
        try container.encode(active, forKey: .active)
    }
}


struct ModelLabel: View {
    var model: ConnectionModel

    var body: some View {
        Text(model.modelName)
    }
}

