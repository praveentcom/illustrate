import Foundation

struct OpenAIModels {
    
    static func createModels() -> [ProviderModel] {
        return [
            ProviderModel(
                providerId: EnumProviderCode.OPENAI.providerId,
                modelId: EnumProviderModelCode.OPENAI_DALLE3.modelId,
                modelCode: EnumProviderModelCode.OPENAI_DALLE3,
                modelSetType: EnumSetType.GENERATE,
                modelName: "DALL·E 3",
                modelDescription: "DALL·E 3 represents a leap forward in our ability to generate images that exactly adhere to the text you provide.",
                modelSupportedParams: ProviderModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1024x1024", "1792x1024", "1024x1792"],
                    quality: true,
                    variant: true,
                    style: true,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-08-20"),
                modelGenerateBaseURL: "https://api.openai.com/v1/images/generations",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/create",
                active: true
            ),
            ProviderModel(
                providerId: EnumProviderCode.OPENAI.providerId,
                modelId: EnumProviderModelCode.OPENAI_GPT_IMAGE_1.modelId,
                modelCode: EnumProviderModelCode.OPENAI_GPT_IMAGE_1,
                modelSetType: EnumSetType.GENERATE,
                modelName: "GPT Image 1",
                modelDescription: "GPT Image 1 is OpenAI's latest image generation model with excellent prompt understanding and high-quality output.",
                modelSupportedParams: ProviderModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1024x1024", "1536x1024", "1024x1536"],
                    quality: true,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: false
                ),
                modelLaunchDate: getDateFromString("2025-04-01"),
                modelGenerateBaseURL: "https://api.openai.com/v1/images/generations",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/create",
                active: true
            ),
            ProviderModel(
                providerId: EnumProviderCode.OPENAI.providerId,
                modelId: EnumProviderModelCode.OPENAI_GPT_IMAGE_1_EDIT.modelId,
                modelCode: EnumProviderModelCode.OPENAI_GPT_IMAGE_1_EDIT,
                modelSetType: EnumSetType.EDIT_MASK,
                modelName: "GPT Image 1",
                modelDescription: "GPT Image 1 edit mode - modify images using prompts and optional masks for precise control.",
                modelSupportedParams: ProviderModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1024x1024", "1536x1024", "1024x1536"],
                    quality: true,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: false
                ),
                modelLaunchDate: getDateFromString("2025-04-01"),
                modelGenerateBaseURL: "https://api.openai.com/v1/images/edits",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/createEdit",
                active: true
            ),
            ProviderModel(
                providerId: EnumProviderCode.OPENAI.providerId,
                modelId: EnumProviderModelCode.OPENAI_SORA_2.modelId,
                modelCode: EnumProviderModelCode.OPENAI_SORA_2,
                modelSetType: EnumSetType.VIDEO_TEXT,
                modelName: "Sora 2",
                modelDescription: "OpenAI's Sora 2 - Generate stunning videos from text prompts.",
                modelSupportedParams: ProviderModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1280x720", "720x1280"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 1,
                    autoEnhance: false,
                    supportedDurations: [4, 8, 12],
                    supportsAudio: false,
                    supportsLastFrame: false,
                    supportsVideoInput: false
                ),
                modelLaunchDate: getDateFromString("2025-02-01"),
                modelGenerateBaseURL: "https://api.openai.com/v1/videos",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/videos/create",
                active: true
            ),
            ProviderModel(
                providerId: EnumProviderCode.OPENAI.providerId,
                modelId: EnumProviderModelCode.OPENAI_SORA_2_PRO.modelId,
                modelCode: EnumProviderModelCode.OPENAI_SORA_2_PRO,
                modelSetType: EnumSetType.VIDEO_TEXT,
                modelName: "Sora 2 Pro",
                modelDescription: "OpenAI's Sora 2 Pro - Premium video generation with higher resolution support.",
                modelSupportedParams: ProviderModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1280x720", "720x1280", "1792x1024", "1024x1792"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 1,
                    autoEnhance: false,
                    supportedDurations: [4, 8, 12],
                    supportsAudio: false,
                    supportsLastFrame: false,
                    supportsVideoInput: false
                ),
                modelLaunchDate: getDateFromString("2025-02-01"),
                modelGenerateBaseURL: "https://api.openai.com/v1/videos",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/videos/create",
                active: true
            )
        ]
    }
}

