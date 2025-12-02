import Foundation

struct ReplicateModels {
    
    static func createModels() -> [ConnectionModel] {
        return [
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
                modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-pro/predictions",
                modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
                modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-pro?input=http",
                active: true
            )
        ]
    }
}

