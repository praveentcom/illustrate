import Foundation
import SwiftData
import SwiftUI

enum EnumPartnerModelCode: String, Codable {
    case OPENAI_DALLE3 = "OPENAI_DALLE3"
    case STABILITY_SDXL = "STABILITY_SDXL"
    case STABILITY_SD3 = "STABILITY_SD3"
    case STABILITY_SD3_TURBO = "STABILITY_SD3_TURBO"
    case STABILITY_CORE = "STABILITY_CORE"
    case STABILITY_ULTRA = "STABILITY_ULTRA"
    case STABILITY_CONSERVATIVE_UPSCALE = "STABILITY_CONSERVATIVE_UPSCALE"
    case STABILITY_CREATIVE_UPSCALE = "STABILITY_CREATIVE_UPSCALE"
    case STABILITY_ERASE = "STABILITY_ERASE"
    case STABILITY_INPAINT = "STABILITY_INPAINT"
    case STABILITY_OUTPAINT = "STABILITY_OUTPAINT"
    case STABILITY_SEARCH_AND_REPLACE = "STABILITY_SEARCH_AND_REPLACE"
    case STABILITY_REMOVE_BACKGROUND = "STABILITY_REMOVE_BACKGROUND"
    case STABILITY_IMAGE_TO_VIDEO = "STABILITY_IMAGE_TO_VIDEO"
    case GCLOUD_IMAGEN2 = "GCLOUD_IMAGEN2"
    case REPLICATE_FLUX_SCHNELL = "REPLICATE_FLUX_SCHNELL"
    case REPLICATE_FLUX_DEV = "REPLICATE_FLUX_DEV"
    case REPLICATE_FLUX_DEV_EDIT = "REPLICATE_FLUX_DEV_EDIT"
    case REPLICATE_FLUX_PRO = "REPLICATE_FLUX_PRO"
}

@Model
final class PartnerModel: Codable {
    enum CodingKeys: CodingKey {
        case partnerId
        case modelId
        case modelCode
        case modelSetType
        case modelName
        case modelDescription
        case modelMaxInputTokens
        case modelSupportedImageDimensions
        case modelNegativePromptSupport
        case modelLaunchDate
        case modelDeprecationDate
        case modelGenerateBaseURL
        case modelStatusBaseURL
        case modelAPIDocumentationURL
        case active
    }
    
    var partnerId: UUID
    var modelId: UUID
    var modelCode: EnumPartnerModelCode
    var modelSetType: EnumSetType
    var modelName: String
    var modelDescription: String
    var modelMaxInputTokens: Int
    var modelSupportedImageDimensions: [String]
    var modelNegativePromptSupport: Bool
    var modelLaunchDate: Date
    var modelDeprecationDate: Date?
    var modelGenerateBaseURL: String
    var modelStatusBaseURL: String?
    var modelAPIDocumentationURL: String
    var active: Bool
    
    init(
        partnerId: UUID,
        modelId: UUID,
        modelCode: EnumPartnerModelCode,
        modelSetType: EnumSetType,
        modelName: String,
        modelDescription: String,
        modelMaxInputTokens: Int,
        modelSupportedImageDimensions: [String],
        modelNegativePromptSupport: Bool = false,
        modelLaunchDate: Date,
        modelDeprecationDate: Date? = nil,
        modelGenerateBaseURL: String,
        modelStatusBaseURL: String? = nil,
        modelAPIDocumentationURL: String,
        active: Bool
    ) {
        self.partnerId = partnerId
        self.modelId = modelId
        self.modelCode = modelCode
        self.modelSetType = modelSetType
        self.modelName = modelName
        self.modelDescription = modelDescription
        self.modelMaxInputTokens = modelMaxInputTokens
        self.modelSupportedImageDimensions = modelSupportedImageDimensions
        self.modelNegativePromptSupport = modelNegativePromptSupport
        self.modelLaunchDate = modelLaunchDate
        self.modelDeprecationDate = modelDeprecationDate
        self.modelGenerateBaseURL = modelGenerateBaseURL
        self.modelStatusBaseURL = modelStatusBaseURL
        self.modelAPIDocumentationURL = modelAPIDocumentationURL
        self.active = active
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partnerId = try container.decode(UUID.self, forKey: .partnerId)
        modelId = try container.decode(UUID.self, forKey: .modelId)
        modelCode = try container.decode(EnumPartnerModelCode.self, forKey: .modelCode)
        modelSetType = try container.decode(EnumSetType.self, forKey: .modelSetType)
        modelName = try container.decode(String.self, forKey: .modelName)
        modelDescription = try container.decode(String.self, forKey: .modelDescription)
        modelMaxInputTokens = try container.decode(Int.self, forKey: .modelMaxInputTokens)
        modelSupportedImageDimensions = try container.decode([String].self, forKey: .modelSupportedImageDimensions)
        modelNegativePromptSupport = try container.decode(Bool.self, forKey: .modelNegativePromptSupport)
        modelLaunchDate = try container.decode(Date.self, forKey: .modelLaunchDate)
        modelDeprecationDate = try container.decodeIfPresent(Date.self, forKey: .modelDeprecationDate)
        modelGenerateBaseURL = try container.decode(String.self, forKey: .modelGenerateBaseURL)
        modelStatusBaseURL = try container.decodeIfPresent(String.self, forKey: .modelStatusBaseURL)
        modelAPIDocumentationURL = try container.decode(String.self, forKey: .modelAPIDocumentationURL)
        active = try container.decode(Bool.self, forKey: .active)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partnerId, forKey: .partnerId)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(modelCode, forKey: .modelCode)
        try container.encode(modelSetType, forKey: .modelSetType)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(modelDescription, forKey: .modelDescription)
        try container.encode(modelMaxInputTokens, forKey: .modelMaxInputTokens)
        try container.encode(modelSupportedImageDimensions, forKey: .modelSupportedImageDimensions)
        try container.encode(modelNegativePromptSupport, forKey: .modelNegativePromptSupport)
        try container.encode(modelLaunchDate, forKey: .modelLaunchDate)
        try container.encode(modelDeprecationDate, forKey: .modelDeprecationDate)
        try container.encode(modelGenerateBaseURL, forKey: .modelGenerateBaseURL)
        try container.encode(modelStatusBaseURL, forKey: .modelStatusBaseURL)
        try container.encode(modelAPIDocumentationURL, forKey: .modelAPIDocumentationURL)
        try container.encode(active, forKey: .active)
    }
}

func getModel(modelId: String) -> PartnerModel? {
    return partnerModels.first(where: { $0.modelId.uuidString == modelId })
}

struct ModelLabel: View {
    var model: PartnerModel
    
    var body: some View {
        Text(model.modelName)
    }
}

let partnerModels = [
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000101")!,
        modelCode: EnumPartnerModelCode.OPENAI_DALLE3,
        modelSetType: EnumSetType.GENERATE,
        modelName: "DALL·E 3",
        modelDescription: "DALL·E 3 represents a leap forward in our ability to generate images that exactly adhere to the text you provide.",
        modelMaxInputTokens: 4000,
        modelSupportedImageDimensions: ["1024x1024","1792x1024","1024x1792"],
        modelLaunchDate: Date(timeIntervalSince1970: 1692530616), // 2023-08-20 12:03:36
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.openai.com/v1/images/generations",
        modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/create",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000201")!,
        modelCode: EnumPartnerModelCode.STABILITY_ULTRA,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable Ultra",
        modelDescription: "Stable Image Ultra creates the highest quality images with unprecedented prompt understanding.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/ultra",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1ultra/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000202")!,
        modelCode: EnumPartnerModelCode.STABILITY_CORE,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable Core",
        modelDescription: "Stable Image Core represents the best quality achievable at high speed.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/core",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1core/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000203")!,
        modelCode: EnumPartnerModelCode.STABILITY_SDXL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable XL 1.0 (SDXL)",
        modelDescription: "Stable Diffusion XL (SDXL) is a powerful text-to-image generation model.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","1152x896","896x1152","1216x832","1344x768","768x1344","1536x640","640x1536"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/SDXL-and-SD1.6",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000204")!,
        modelCode: EnumPartnerModelCode.STABILITY_SD3,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable 3.0 Large",
        modelDescription: "Generate images using Stable Diffusion 3 Large (SD3).",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000205")!,
        modelCode: EnumPartnerModelCode.STABILITY_SD3_TURBO,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Stable 3.0 Turbo",
        modelDescription: "Generate images using Stable Diffusion 3 Large Turbo (SD3 Turbo).",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","1344x576","576x1344","1536x1024","1024x1536","1280x1024","1024x1280"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000206")!,
        modelCode: EnumPartnerModelCode.STABILITY_CREATIVE_UPSCALE,
        modelSetType: EnumSetType.EDIT_UPSCALE,
        modelName: "Stable Creative Upscale",
        modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/creative",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1creative/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000207")!,
        modelCode: EnumPartnerModelCode.STABILITY_CONSERVATIVE_UPSCALE,
        modelSetType: EnumSetType.EDIT_UPSCALE,
        modelName: "Stable Conservative Upscale",
        modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/conservative",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1conservative/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000208")!,
        modelCode: EnumPartnerModelCode.STABILITY_ERASE,
        modelSetType: EnumSetType.EDIT_MASK_ERASE,
        modelName: "Stable Erase",
        modelDescription: "The Erase service removes unwanted objects, such as blemishes on portraits or items on desks, using image masks.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/erase",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1erase/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000209")!,
        modelCode: EnumPartnerModelCode.STABILITY_INPAINT,
        modelSetType: EnumSetType.EDIT_MASK,
        modelName: "Stable Inpaint",
        modelDescription: "Intelligently modify images by filling in or replacing specified areas with new content based on the content of a mask image.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/inpaint",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1inpaint/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000210")!,
        modelCode: EnumPartnerModelCode.STABILITY_OUTPAINT,
        modelSetType: EnumSetType.EDIT_EXPAND,
        modelName: "Stable Outpaint",
        modelDescription: "The Outpaint service inserts additional content in an image to fill in the space in any direction.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/outpaint",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1outpaint/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000211")!,
        modelCode: EnumPartnerModelCode.STABILITY_SEARCH_AND_REPLACE,
        modelSetType: EnumSetType.EDIT_REPLACE,
        modelName: "Stable Search and Replace",
        modelDescription: "The Search and Replace service is a specific version of inpainting that does not require a mask.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/search-and-replace",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1search-and-replace/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000212")!,
        modelCode: EnumPartnerModelCode.STABILITY_REMOVE_BACKGROUND,
        modelSetType: EnumSetType.REMOVE_BACKGROUND,
        modelName: "Stable Remove Background",
        modelDescription: "The Remove Background service accurately segments the foreground from an image and implements and removes the background.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/remove-background",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1remove-background/post",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000213")!,
        modelCode: EnumPartnerModelCode.STABILITY_IMAGE_TO_VIDEO,
        modelSetType: EnumSetType.VIDEO_IMAGE,
        modelName: "Stable Image to Video",
        modelDescription: "Generate a short video based on an initial image with Stable Video Diffusion, a latent video diffusion model.",
        modelMaxInputTokens: 1024,
        modelSupportedImageDimensions: ["768x768","576x1024","1024x576"],
        modelNegativePromptSupport: false,
        modelLaunchDate: Date(timeIntervalSince1970: 1690347042), // 2023-07-26 05:50:42
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.stability.ai/v2beta/image-to-video",
        modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Image-to-Video",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000301")!,
        modelCode: EnumPartnerModelCode.GCLOUD_IMAGEN2,
        modelSetType: EnumSetType.GENERATE,
        modelName: "Imagen 2",
        modelDescription: "Text-to-image diffusion technology, delivering photorealistic outputs that are aligned and consistent with the user’s prompt.",
        modelMaxInputTokens: 256,
        modelSupportedImageDimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
        modelNegativePromptSupport: true,
        modelLaunchDate: Date(timeIntervalSince1970: 1702440977), // 2023-12-13 12:16:17
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "us-central1-aiplatform.googleapis.com",
        modelAPIDocumentationURL: "https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/image-generation",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000401")!,
        modelCode: EnumPartnerModelCode.REPLICATE_FLUX_PRO,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [pro]",
        modelDescription: "State-of-the-art image generation with top of the line prompt following, visual quality, image detail and output diversity.",
        modelMaxInputTokens: 256,
        modelSupportedImageDimensions: ["1024x1024", "1920x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920"],
        modelNegativePromptSupport: false,
        modelLaunchDate: Date(timeIntervalSince1970: 1702440977), // 2023-12-13 12:16:17
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-pro/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-pro?input=http",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000402")!,
        modelCode: EnumPartnerModelCode.REPLICATE_FLUX_DEV,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [dev]",
        modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
        modelMaxInputTokens: 256,
        modelSupportedImageDimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
        modelNegativePromptSupport: false,
        modelLaunchDate: Date(timeIntervalSince1970: 1702440977), // 2023-12-13 12:16:17
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-dev/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-dev?input=http",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000403")!,
        modelCode: EnumPartnerModelCode.REPLICATE_FLUX_DEV_EDIT,
        modelSetType: EnumSetType.EDIT_PROMPT,
        modelName: "FLUX.1 [dev]",
        modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
        modelMaxInputTokens: 256,
        modelSupportedImageDimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
        modelNegativePromptSupport: false,
        modelLaunchDate: Date(timeIntervalSince1970: 1702440977), // 2023-12-13 12:16:17
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-dev/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-dev?input=http",
        active: true
    ),
    PartnerModel(
        partnerId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
        modelId: UUID(uuidString: "20000000-0000-0000-0000-000000000404")!,
        modelCode: EnumPartnerModelCode.REPLICATE_FLUX_SCHNELL,
        modelSetType: EnumSetType.GENERATE,
        modelName: "FLUX.1 [schnell]",
        modelDescription: "The fastest image generation model tailored for local development and personal use.",
        modelMaxInputTokens: 256,
        modelSupportedImageDimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
        modelNegativePromptSupport: false,
        modelLaunchDate: Date(timeIntervalSince1970: 1702440977), // 2023-12-13 12:16:17
        modelDeprecationDate: nil,
        modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-schnell/predictions",
        modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
        modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-schnell?input=http",
        active: true
    ),
]
