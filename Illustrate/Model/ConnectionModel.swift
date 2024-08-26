import Foundation
import SwiftData
import SwiftUI

enum EnumConnectionModelCode: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case OPENAI_DALLE3
    case STABILITY_SDXL
    case STABILITY_SD3
    case STABILITY_SD3_TURBO
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
    case GCLOUD_IMAGEN2
    case REPLICATE_FLUX_SCHNELL
    case REPLICATE_FLUX_DEV
    case REPLICATE_FLUX_PRO
    case FAL_FLUX_SCHNELL
    case FAL_FLUX_DEV
    case FAL_FLUX_PRO
    case HUGGING_FACE_FLUX_SCHNELL
    case HUGGING_FACE_FLUX_DEV
    
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
        case .GCLOUD_IMAGEN2:
            return UUID(uuidString: "20000000-0000-0000-0000-000000000301")!
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
    
    init(
        prompt: Bool,
        negativePrompt: Bool,
        maxPromptLength: Int,
        dimensions: [String],
        quality: Bool,
        variant: Bool,
        style: Bool,
        count: Int,
        autoEnhance: Bool
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

func getModel(modelId: String) -> ConnectionModel? {
    return connectionModels.first(where: { $0.modelId.uuidString == modelId })
}

struct ModelLabel: View {
    var model: ConnectionModel
    
    var body: some View {
        Text(model.modelName)
    }
}

let connectionModels = [
    ConnectionModel(
        connectionId: EnumConnectionCode.OPENAI.connectionId,
        modelId: EnumConnectionModelCode.OPENAI_DALLE3.modelId,
        modelCode: EnumConnectionModelCode.OPENAI_DALLE3,
        modelSetType: EnumSetType.GENERATE,
        modelName: "DALL·E 3",
        modelDescription: "DALL·E 3 represents a leap forward in our ability to generate images that exactly adhere to the text you provide.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: false,
            maxPromptLength: 4000,
            dimensions: ["1024x1024","1792x1024","1024x1792"],
            quality: true,
            variant: true,
            style: true,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-08-20"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.openai.com/v1/images/generations",
        modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/create",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_ULTRA.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_ULTRA,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable Ultra",
        modelDescription: "Stable Image Ultra creates the highest quality images with unprecedented prompt understanding.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/ultra",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1ultra/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_CORE.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_CORE,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable Core",
        modelDescription: "Stable Image Core represents the best quality achievable at high speed.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/core",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1core/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_SDXL.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_SDXL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable XL 1.0 (SDXL)",
        modelDescription: "Stable Diffusion XL (SDXL) is a powerful text-to-image generation model.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","1152x896","896x1152","1216x832","1344x768","768x1344","1536x640","640x1536"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/SDXL-and-SD1.6",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_SD3.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_SD3,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable 3.0 Large",
        modelDescription: "Generate images using Stable Diffusion 3 Large (SD3).",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_SD3_TURBO.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_SD3_TURBO,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable 3.0 Turbo",
        modelDescription: "Generate images using Stable Diffusion 3 Large Turbo (SD3 Turbo).",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE,
        modelSetType: EnumSetType.EDIT_UPSCALE,
        modelName: "Stable Creative Upscale",
        modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/creative",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1creative/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_CONSERVATIVE_UPSCALE.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_CONSERVATIVE_UPSCALE,
        modelSetType: EnumSetType.EDIT_UPSCALE,
        modelName: "Stable Conservative Upscale",
        modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/conservative",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1conservative/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_ERASE.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_ERASE,
        modelSetType: EnumSetType.EDIT_MASK_ERASE,
        modelName: "Stable Erase",
        modelDescription: "The Erase service removes unwanted objects, such as blemishes on portraits or items on desks, using image masks.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/erase",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1erase/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_INPAINT.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_INPAINT,
        modelSetType: EnumSetType.EDIT_MASK,
        modelName: "Stable Inpaint",
        modelDescription: "Intelligently modify images by filling in or replacing specified areas with new content based on the content of a mask image.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/inpaint",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1inpaint/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_OUTPAINT.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_OUTPAINT,
        modelSetType: EnumSetType.EDIT_EXPAND,
        modelName: "Stable Outpaint",
        modelDescription: "The Outpaint service inserts additional content in an image to fill in the space in any direction.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/outpaint",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1outpaint/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_SEARCH_AND_REPLACE.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_SEARCH_AND_REPLACE,
        modelSetType: EnumSetType.EDIT_REPLACE,
        modelName: "Stable Search and Replace",
        modelDescription: "The Search and Replace service is a specific version of inpainting that does not require a mask.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/search-and-replace",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1search-and-replace/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_REMOVE_BACKGROUND.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_REMOVE_BACKGROUND,
        modelSetType: EnumSetType.REMOVE_BACKGROUND,
        modelName: "Stable Remove Background",
        modelDescription: "The Remove Background service accurately segments the foreground from an image and implements and removes the background.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/remove-background",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1remove-background/post",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
        modelId: EnumConnectionModelCode.STABILITY_IMAGE_TO_VIDEO.modelId,
        modelCode: EnumConnectionModelCode.STABILITY_IMAGE_TO_VIDEO,
        modelSetType: EnumSetType.VIDEO_IMAGE,
        modelName: "Stable Image to Video",
        modelDescription: "Generate a short video based on an initial image with Stable Video Diffusion, a latent video diffusion model.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 1024,
            dimensions: ["768x768","576x1024","1024x576"],
            quality: false,
            variant: false,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/image-to-video",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Image-to-Video",
        active: true
    ),
//    ConnectionModel(
//        connectionId:EnumConnectionCode.GOOGLE_CLOUD.connectionId,
//        modelId: EnumConnectionModelCode.GCLOUD_IMAGEN2.modelId,
//        modelCode: EnumConnectionModelCode.GCLOUD_IMAGEN2,
//        modelSetType: EnumSetType.GENERATE,
//        modelName: "Imagen 2",
//        modelDescription: "Text-to-image diffusion technology, delivering photorealistic outputs that are aligned and consistent with the user’s prompt.",
//        modelSupportedParams: ConnectionModelSupportParams(
//            prompt: true,
//            negativePrompt: true,
//            maxPromptLength: 256,
//            dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
//            quality: false,
//            variant: true,
//            style: false,
//            count: 6,
//            autoEnhance: true
//        ),
//        modelLaunchDate: getDateFromString("2023-07-26"),
//        modelDeprecationDate: nil,
//        modelGenerateBaseURL: "us-central1-aiplatform.googleapis.com",
//        modelAPIDocumentationURL: "https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/image-generation",
//        active: true
//    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.REPLICATE.connectionId,
        modelId: EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL.modelId,
        modelCode: EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [schnell]",
        modelDescription: "The fastest image generation model tailored for local development and personal use.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-schnell/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-schnell?input=http",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.REPLICATE.connectionId,
        modelId: EnumConnectionModelCode.REPLICATE_FLUX_DEV.modelId,
        modelCode: EnumConnectionModelCode.REPLICATE_FLUX_DEV,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [dev]",
        modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-dev/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-dev?input=http",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.REPLICATE.connectionId,
        modelId: EnumConnectionModelCode.REPLICATE_FLUX_PRO.modelId,
        modelCode: EnumConnectionModelCode.REPLICATE_FLUX_PRO,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [pro]",
        modelDescription: "State-of-the-art image generation with top of the line prompt following, visual quality, image detail and output diversity.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-pro/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-pro?input=http",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.FAL_AI.connectionId,
        modelId: EnumConnectionModelCode.FAL_FLUX_SCHNELL.modelId,
        modelCode: EnumConnectionModelCode.FAL_FLUX_SCHNELL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [schnell]",
        modelDescription: "The fastest image generation model tailored for local development and personal use.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://fal.run/fal-ai/flux/schnell",
        modelStatusBaseURL: nil,
        modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux/schnell",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.FAL_AI.connectionId,
        modelId: EnumConnectionModelCode.FAL_FLUX_DEV.modelId,
        modelCode: EnumConnectionModelCode.FAL_FLUX_DEV,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [dev]",
        modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://fal.run/fal-ai/flux/dev",
        modelStatusBaseURL: nil,
        modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux/dev",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.FAL_AI.connectionId,
        modelId: EnumConnectionModelCode.FAL_FLUX_PRO.modelId,
        modelCode: EnumConnectionModelCode.FAL_FLUX_PRO,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [pro]",
        modelDescription: "State-of-the-art image generation with top of the line prompt following, visual quality, image detail and output diversity.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
            quality: false,
            variant: true,
            style: false,
            count: 6,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-07-26"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://fal.run/fal-ai/flux-pro",
        modelStatusBaseURL: nil,
        modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux-pro",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.HUGGING_FACE.connectionId,
        modelId: EnumConnectionModelCode.HUGGING_FACE_FLUX_SCHNELL.modelId,
        modelCode: EnumConnectionModelCode.HUGGING_FACE_FLUX_SCHNELL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [schnell]",
        modelDescription: "The fastest image generation model tailored for local development and personal use.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024"],
            quality: false,
            variant: true,
            style: false,
            count: 1,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell",
        modelStatusBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell",
        modelAPIDocumentationURL: "https://huggingface.co/spaces/black-forest-labs/FLUX.1-schnell",
        active: true
    ),
    ConnectionModel(
        connectionId: EnumConnectionCode.HUGGING_FACE.connectionId,
        modelId: EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV.modelId,
        modelCode: EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [dev]",
        modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
        modelSupportedParams: ConnectionModelSupportParams(
            prompt: true,
            negativePrompt: true,
            maxPromptLength: 256,
            dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
            quality: false,
            variant: true,
            style: false,
            count: 1,
            autoEnhance: true
        ),
        modelLaunchDate: getDateFromString("2023-12-13"),
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-dev",
        modelStatusBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-dev",
        modelAPIDocumentationURL: "https://huggingface.co/spaces/black-forest-labs/FLUX.1-dev",
        active: true
    )
]
