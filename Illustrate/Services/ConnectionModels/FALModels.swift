import Foundation

struct FALModels {
    
    static func createModels() -> [ConnectionModel] {
        return [
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
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux/schnell",
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
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux/dev",
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
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux-pro",
                modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux-pro",
                active: true
            )
        ]
    }
}

